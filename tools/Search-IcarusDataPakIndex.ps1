param(
    [string]$Query = "",
    [string]$Table = "",
    [string]$IndexDirectory = "",
    [int]$Top = 30,
    [switch]$TablesOnly,
    [switch]$LinksOnly,
    [switch]$ItemsOnly,
    [switch]$MissingLinksOnly
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $IndexDirectory) { $IndexDirectory = Join-Path $workspaceRoot "Notes\IcarusDataPakIndex" }

function Shorten {
    param([string]$Text, [int]$Length = 180)
    if (-not $Text) { return "" }
    if ($Text.Length -le $Length) { return $Text }
    return $Text.Substring(0, $Length - 3) + "..."
}

function Import-CsvIfExists {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Index file not found: $Path. Build the index first." }
    return @(Import-Csv -LiteralPath $Path)
}

$terms = @($Query -split "\s+" | Where-Object { $_ })

function Get-Score {
    param($Object, [string[]]$Terms)
    if (-not $Terms -or $Terms.Count -eq 0) { return 1 }
    $text = ($Object.PSObject.Properties | ForEach-Object { [string]$_.Value }) -join " "
    $score = 0
    foreach ($term in $Terms) {
        $pattern = [regex]::Escape($term)
        foreach ($prop in $Object.PSObject.Properties) {
            $value = [string]$prop.Value
            if ($value -match $pattern) {
                switch -Regex ($prop.Name) {
                    "^(TableName|RowName|Item|SourceRow|TargetRow|Title)$" { $score += 8; break }
                    "^(Fields|Categories|FieldPath)$" { $score += 4; break }
                    default { $score += 2; break }
                }
            }
        }
        if ($text -match $pattern) { $score += 1 }
    }
    return $score
}

function Show-Result {
    param($Item, [string]$Kind)
    Write-Output ("[{0}] {1}" -f $Item.Score, $Kind)
    switch ($Kind) {
        "Table" {
            Write-Output ("    {0}  Rows={1}  Struct={2}" -f $Item.TableName, $Item.RowCount, $Item.RowStruct)
            if ($Item.Categories) { Write-Output ("    Categories: {0}" -f (Shorten $Item.Categories 140)) }
            if ($Item.Fields) { Write-Output ("    Fields: {0}" -f (Shorten $Item.Fields 180)) }
            Write-Output ("    Path: {0}" -f $Item.RelativePath)
        }
        "Row" {
            Write-Output ("    {0}.{1}" -f $Item.TableName, $Item.RowName)
            if ($Item.PrimitiveSummary) { Write-Output ("    Summary: {0}" -f (Shorten $Item.PrimitiveSummary 220)) }
            if ($Item.Fields) { Write-Output ("    Fields: {0}" -f (Shorten $Item.Fields 180)) }
            Write-Output ("    Path: {0}" -f $Item.RelativePath)
        }
        "Link" {
            Write-Output ("    {0}.{1} :: {2} -> {3}.{4}" -f $Item.SourceTable, $Item.SourceRow, $Item.FieldPath, $Item.TargetTable, $Item.TargetRow)
        }
        "MissingLink" {
            Write-Output ("    {0}: {1}.{2} :: {3} -> {4}.{5}" -f $Item.Status, $Item.SourceTable, $Item.SourceRow, $Item.FieldPath, $Item.TargetTable, $Item.TargetRow)
        }
        "Item" {
            Write-Output ("    {0}" -f $Item.Item)
            Write-Output ("    Meshable={0}; Itemable={1}; Deployable={2}; Inventory={3}; InventoryContainer={4}" -f $Item.Meshable, $Item.Itemable, $Item.Deployable, $Item.Inventory, $Item.InventoryContainer)
            if ($Item.ManualTags -or $Item.GeneratedTags) { Write-Output ("    Tags: {0} {1}" -f (Shorten $Item.ManualTags 90), (Shorten $Item.GeneratedTags 90)) }
        }
    }
    Write-Output ""
}

$datasets = New-Object System.Collections.Generic.List[object]

if ($TablesOnly -or (-not $LinksOnly -and -not $ItemsOnly -and -not $MissingLinksOnly)) {
    foreach ($row in Import-CsvIfExists (Join-Path $IndexDirectory "datapak-table-index.csv")) {
        if ($Table -and $row.TableName -ne $Table) { continue }
        $score = Get-Score $row $terms
        if ($score -gt 0) {
            $row | Add-Member -NotePropertyName Score -NotePropertyValue $score -Force
            $datasets.Add([pscustomobject]@{ Kind = "Table"; Data = $row; Score = $score }) | Out-Null
        }
    }
}

if (-not $TablesOnly -and -not $LinksOnly -and -not $ItemsOnly -and -not $MissingLinksOnly) {
    foreach ($row in Import-CsvIfExists (Join-Path $IndexDirectory "datapak-row-index.csv")) {
        if ($Table -and $row.TableName -ne $Table) { continue }
        $score = Get-Score $row $terms
        if ($score -gt 0) {
            $row | Add-Member -NotePropertyName Score -NotePropertyValue $score -Force
            $datasets.Add([pscustomobject]@{ Kind = "Row"; Data = $row; Score = $score }) | Out-Null
        }
    }
}

if ($LinksOnly -or (-not $TablesOnly -and -not $ItemsOnly -and -not $MissingLinksOnly -and $Query)) {
    foreach ($row in Import-CsvIfExists (Join-Path $IndexDirectory "datapak-rowhandle-links.csv")) {
        if ($Table -and $row.SourceTable -ne $Table -and $row.TargetTable -ne $Table) { continue }
        $score = Get-Score $row $terms
        if ($score -gt 0) {
            $row | Add-Member -NotePropertyName Score -NotePropertyValue $score -Force
            $datasets.Add([pscustomobject]@{ Kind = "Link"; Data = $row; Score = $score }) | Out-Null
        }
    }
}

if ($MissingLinksOnly) {
    foreach ($row in Import-CsvIfExists (Join-Path $IndexDirectory "datapak-missing-rowhandle-links.csv")) {
        if ($Table -and $row.SourceTable -ne $Table -and $row.TargetTable -ne $Table) { continue }
        $score = Get-Score $row $terms
        if ($score -gt 0) {
            $row | Add-Member -NotePropertyName Score -NotePropertyValue $score -Force
            $datasets.Add([pscustomobject]@{ Kind = "MissingLink"; Data = $row; Score = $score }) | Out-Null
        }
    }
}

if ($ItemsOnly -or (-not $TablesOnly -and -not $LinksOnly -and -not $MissingLinksOnly -and $Query)) {
    foreach ($row in Import-CsvIfExists (Join-Path $IndexDirectory "datapak-item-connections.csv")) {
        $score = Get-Score $row $terms
        if ($score -gt 0) {
            $row | Add-Member -NotePropertyName Score -NotePropertyValue $score -Force
            $datasets.Add([pscustomobject]@{ Kind = "Item"; Data = $row; Score = $score }) | Out-Null
        }
    }
}

$results = @(
    $datasets |
        Sort-Object @{ Expression = "Score"; Descending = $true }, @{ Expression = { $_.Data.TableName } }, @{ Expression = { $_.Data.RowName } }, @{ Expression = { $_.Data.Item } } |
        Select-Object -First $Top
)

foreach ($result in $results) {
    Show-Result $result.Data $result.Kind
}
