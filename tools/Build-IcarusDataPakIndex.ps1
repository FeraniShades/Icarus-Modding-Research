param(
    [string]$SourceDirectory = "",
    [string]$OutputDirectory = "",
    [string]$SnapshotDirectory = "",
    [string]$VersionLabel = (Get-Date -Format "yyyy-MM-dd"),
    [switch]$CreateArchive
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $SourceDirectory) { $SourceDirectory = Join-Path $workspaceRoot "data" }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $workspaceRoot "Notes\IcarusDataPakIndex" }
if (-not $SnapshotDirectory) { $SnapshotDirectory = Join-Path $workspaceRoot "Backups\DataPakSnapshots" }

$systemFields = @("Name", "RowStruct", "Defaults", "Rows")
$categoryTerms = [ordered]@{
    Items             = @("item", "meshable", "itemable", "slot", "weight", "durable", "consume", "food", "resource")
    CraftingRecipes   = @("recipe", "processor", "craft", "input", "output", "recipeset", "bench")
    Deployables       = @("deploy", "buildable", "interactable", "hitable", "focusable", "highlight")
    InventoryStorage  = @("inventory", "container", "bag", "pouch", "slottemplate", "alteration")
    AIAndMounts       = @("ai", "mount", "tame", "saddle", "creature", "goap", "spawn", "growth", "genetic")
    DLCAndGates       = @("dlc", "requiredflag", "sessionrequirement", "requirement", "featurelevel", "characterflag")
    StatsModifiers    = @("stat", "modifier", "aura", "buff", "debuff", "talent", "effect")
    WorldWeather      = @("weather", "storm", "lightning", "water", "world", "biome", "prospect")
    CombatWeapons     = @("weapon", "ammo", "ballistic", "damage", "projectile", "firearm", "melee")
    UIAudioText       = @("ui", "widget", "audio", "sound", "text", "localization", "icon")
}

function Get-TableNameFromPath {
    param([string]$Path)
    return [IO.Path]::GetFileNameWithoutExtension($Path)
}

function Normalize-PathKey {
    param([string]$Path)
    return ($Path -replace "\[\d+\]", "[]")
}

function Add-DefaultRowHandleMaps {
    param(
        $Node,
        [string]$Path,
        [hashtable]$DefaultTableByPath
    )

    if ($null -eq $Node) { return }

    if ($Node -is [pscustomobject] -or $Node -is [System.Collections.IDictionary]) {
        $props = @($Node.PSObject.Properties)
        $rowNameProp = $props | Where-Object Name -eq "RowName" | Select-Object -First 1
        $dataTableProp = $props | Where-Object Name -eq "DataTableName" | Select-Object -First 1
        if ($rowNameProp -and $dataTableProp -and $dataTableProp.Value) {
            $DefaultTableByPath[(Normalize-PathKey $Path)] = [string]$dataTableProp.Value
        }

        foreach ($prop in $props) {
            if ($prop.Name -in @("RowName", "DataTableName")) { continue }
            $childPath = if ($Path) { "$Path.$($prop.Name)" } else { $prop.Name }
            Add-DefaultRowHandleMaps $prop.Value $childPath $DefaultTableByPath
        }
    }
    elseif ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        $i = 0
        foreach ($item in @($Node)) {
            Add-DefaultRowHandleMaps $item "$Path[$i]" $DefaultTableByPath
            $i++
        }
    }
}

function Find-DefaultTableForPath {
    param(
        [hashtable]$DefaultTableByPath,
        [string]$Path
    )

    $key = Normalize-PathKey $Path
    while ($key) {
        if ($DefaultTableByPath.ContainsKey($key)) { return $DefaultTableByPath[$key] }
        $lastDot = $key.LastIndexOf(".")
        if ($lastDot -lt 0) { break }
        $key = $key.Substring(0, $lastDot)
    }
    return ""
}

function Add-RowHandleLinks {
    param(
        $Node,
        [string]$Path,
        [hashtable]$DefaultTableByPath,
        [System.Collections.Generic.List[object]]$Links,
        [string]$SourceTable,
        [string]$SourceRow
    )

    if ($null -eq $Node) { return }

    if ($Node -is [pscustomobject] -or $Node -is [System.Collections.IDictionary]) {
        $props = @($Node.PSObject.Properties)
        $rowNameProp = $props | Where-Object Name -eq "RowName" | Select-Object -First 1
        if ($rowNameProp) {
            $targetRow = [string]$rowNameProp.Value
            if ($targetRow -and $targetRow -ne "None") {
                $dataTableProp = $props | Where-Object Name -eq "DataTableName" | Select-Object -First 1
                $targetTable = if ($dataTableProp -and $dataTableProp.Value) { [string]$dataTableProp.Value } else { Find-DefaultTableForPath $DefaultTableByPath $Path }
                $Links.Add([pscustomobject]@{
                    SourceTable = $SourceTable
                    SourceRow = $SourceRow
                    FieldPath = $Path
                    TargetTable = $targetTable
                    TargetRow = $targetRow
                }) | Out-Null
            }
        }

        foreach ($prop in $props) {
            if ($prop.Name -in @("RowName", "DataTableName")) { continue }
            $childPath = if ($Path) { "$Path.$($prop.Name)" } else { $prop.Name }
            Add-RowHandleLinks $prop.Value $childPath $DefaultTableByPath $Links $SourceTable $SourceRow
        }
    }
    elseif ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        $i = 0
        foreach ($item in @($Node)) {
            Add-RowHandleLinks $item "$Path[$i]" $DefaultTableByPath $Links $SourceTable $SourceRow
            $i++
        }
    }
}

function Get-PrimitiveSummary {
    param($Row)
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($prop in @($Row.PSObject.Properties)) {
        if ($prop.Name -eq "Name") { continue }
        $value = $prop.Value
        if ($null -eq $value) { continue }
        if ($value -is [string] -or $value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [bool]) {
            $text = [string]$value
            if ($text.Length -gt 48) { $text = $text.Substring(0, 45) + "..." }
            $parts.Add("$($prop.Name)=$text") | Out-Null
        }
        if ($parts.Count -ge 12) { break }
    }
    return (@($parts) -join "; ")
}

function Get-CategoryTags {
    param(
        [string]$TableName,
        [string]$RowStruct,
        [string[]]$FieldNames
    )

    $haystack = (($TableName, $RowStruct) + $FieldNames) -join " "
    $tags = New-Object System.Collections.Generic.List[string]
    foreach ($category in $categoryTerms.Keys) {
        foreach ($term in $categoryTerms[$category]) {
            if ($haystack -match [regex]::Escape($term)) {
                $tags.Add($category) | Out-Null
                break
            }
        }
    }
    return @($tags)
}

if (-not (Test-Path -LiteralPath $SourceDirectory)) {
    throw "Source directory not found: $SourceDirectory"
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $SnapshotDirectory | Out-Null

$files = Get-ChildItem -LiteralPath $SourceDirectory -Recurse -File -Filter "*.json" | Sort-Object FullName
$tableRowsByName = @{}
$parsedTables = @{}

foreach ($file in $files) {
    $tableName = Get-TableNameFromPath $file.FullName
    try {
        $json = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        $rows = @($json.Rows)
        $tableRowsByName[$tableName] = @{}
        foreach ($row in $rows) {
            if ($row.Name) { $tableRowsByName[$tableName][[string]$row.Name] = $true }
        }
        $parsedTables[$file.FullName] = $json
    }
    catch {
        $tableRowsByName[$tableName] = @{}
    }
}

$tableIndex = New-Object System.Collections.Generic.List[object]
$rowIndex = New-Object System.Collections.Generic.List[object]
$links = New-Object System.Collections.Generic.List[object]
$itemConnections = New-Object System.Collections.Generic.List[object]
$parseErrors = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
    $relativePath = Resolve-Path -LiteralPath $file.FullName -Relative
    $relativePath = $relativePath -replace "^\.\\", ""
    $tableName = Get-TableNameFromPath $file.FullName

    try {
        if ($parsedTables.ContainsKey($file.FullName)) {
            $json = $parsedTables[$file.FullName]
        }
        else {
            $json = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        }

        $rows = @($json.Rows)
        $defaults = $json.Defaults
        $defaultTableByPath = @{}
        Add-DefaultRowHandleMaps $defaults "" $defaultTableByPath
        $fieldNames = @()
        foreach ($row in $rows | Select-Object -First 25) {
            $fieldNames += @($row.PSObject.Properties.Name | Where-Object { $_ -notin $systemFields })
        }
        $fieldNames = @($fieldNames | Sort-Object -Unique)
        $categoryTags = Get-CategoryTags $tableName ([string]$json.RowStruct) $fieldNames

        $tableIndex.Add([pscustomobject]@{
            TableName = $tableName
            RelativePath = $relativePath
            RowStruct = [string]$json.RowStruct
            RowCount = $rows.Count
            SizeBytes = $file.Length
            LastWriteTime = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Categories = (@($categoryTags) -join "; ")
            Fields = (@($fieldNames) -join "; ")
            DefaultRowHandleFields = (@($defaultTableByPath.GetEnumerator() | ForEach-Object { "$($_.Key)->$($_.Value)" }) -join "; ")
        }) | Out-Null

        foreach ($row in $rows) {
            $rowName = [string]$row.Name
            if (-not $rowName) { continue }
            $rowFields = @($row.PSObject.Properties.Name | Where-Object { $_ -ne "Name" })
            $rowIndex.Add([pscustomobject]@{
                TableName = $tableName
                RowName = $rowName
                RelativePath = $relativePath
                RowStruct = [string]$json.RowStruct
                Fields = (@($rowFields) -join "; ")
                PrimitiveSummary = Get-PrimitiveSummary $row
            }) | Out-Null

            Add-RowHandleLinks $row "" $defaultTableByPath $links $tableName $rowName
        }
    }
    catch {
        $parseErrors.Add([pscustomobject]@{
            TableName = $tableName
            RelativePath = $relativePath
            Error = $_.Exception.Message
        }) | Out-Null
    }
}

$missingLinks = New-Object System.Collections.Generic.List[object]
foreach ($link in $links) {
    $status = "OK"
    if (-not $link.TargetTable) {
        $status = "MissingTargetTableName"
    }
    elseif (-not $tableRowsByName.ContainsKey($link.TargetTable)) {
        $status = "MissingTargetTable"
    }
    elseif (-not $tableRowsByName[$link.TargetTable].ContainsKey($link.TargetRow)) {
        $status = "MissingTargetRow"
    }

    if ($status -ne "OK") {
        $missingLinks.Add([pscustomobject]@{
            Status = $status
            SourceTable = $link.SourceTable
            SourceRow = $link.SourceRow
            FieldPath = $link.FieldPath
            TargetTable = $link.TargetTable
            TargetRow = $link.TargetRow
        }) | Out-Null
    }
}

$itemsTable = $parsedTables.Values | Where-Object { $_.RowStruct -eq "/Script/Icarus.ItemStaticData" } | Select-Object -First 1
if ($itemsTable) {
    foreach ($row in @($itemsTable.Rows)) {
        $itemConnections.Add([pscustomobject]@{
            Item = [string]$row.Name
            Meshable = [string]$row.Meshable.RowName
            Itemable = [string]$row.Itemable.RowName
            Deployable = [string]$row.Deployable.RowName
            Buildable = [string]$row.Buildable.RowName
            Interactable = [string]$row.Interactable.RowName
            Inventory = [string]$row.Inventory.RowName
            InventoryContainer = [string]$row.InventoryContainer.RowName
            Consumable = [string]$row.Consumable.RowName
            Resource = [string]$row.Resource.RowName
            Ballistic = [string]$row.Ballistic.RowName
            RequiredFeatureLevel = [string]$row.RequiredFeatureLevel.RowName
            ManualTags = (@($row.Manual_Tags.GameplayTags) -join "; ")
            GeneratedTags = (@($row.Generated_Tags.GameplayTags) -join "; ")
        }) | Out-Null
    }
}

$tableIndexPath = Join-Path $OutputDirectory "datapak-table-index.csv"
$rowIndexPath = Join-Path $OutputDirectory "datapak-row-index.csv"
$linksPath = Join-Path $OutputDirectory "datapak-rowhandle-links.csv"
$missingLinksPath = Join-Path $OutputDirectory "datapak-missing-rowhandle-links.csv"
$missingTargetRowsPath = Join-Path $OutputDirectory "datapak-missing-target-rows.csv"
$itemConnectionsPath = Join-Path $OutputDirectory "datapak-item-connections.csv"
$parseErrorsPath = Join-Path $OutputDirectory "datapak-parse-errors.csv"
$summaryPath = Join-Path $OutputDirectory "README.md"
$manifestPath = Join-Path $OutputDirectory "datapak-index-manifest.json"

$tableIndex | Export-Csv -LiteralPath $tableIndexPath -NoTypeInformation
$rowIndex | Export-Csv -LiteralPath $rowIndexPath -NoTypeInformation
$links | Export-Csv -LiteralPath $linksPath -NoTypeInformation
$missingLinks | Export-Csv -LiteralPath $missingLinksPath -NoTypeInformation
$missingLinks | Where-Object Status -eq "MissingTargetRow" | Export-Csv -LiteralPath $missingTargetRowsPath -NoTypeInformation
$itemConnections | Export-Csv -LiteralPath $itemConnectionsPath -NoTypeInformation
$parseErrors | Export-Csv -LiteralPath $parseErrorsPath -NoTypeInformation

$archivePath = ""
if ($CreateArchive) {
    $safeVersion = $VersionLabel -replace "[^\w\-]+", "_"
    $archivePath = Join-Path $SnapshotDirectory "DataPak-$safeVersion.zip"
    if (Test-Path -LiteralPath $archivePath) {
        $archivePath = Join-Path $SnapshotDirectory "DataPak-$safeVersion-$(Get-Date -Format 'HHmmss').zip"
    }
    Compress-Archive -LiteralPath $SourceDirectory -DestinationPath $archivePath -CompressionLevel Optimal
}

$manifest = [pscustomobject]@{
    SourceDirectory = $SourceDirectory
    OutputDirectory = $OutputDirectory
    SnapshotDirectory = $SnapshotDirectory
    VersionLabel = $VersionLabel
    GeneratedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    TableCount = $tableIndex.Count
    RowCount = $rowIndex.Count
    RowHandleLinkCount = $links.Count
    MissingRowHandleLinkCount = $missingLinks.Count
    ItemConnectionCount = $itemConnections.Count
    ParseErrorCount = $parseErrors.Count
    ArchivePath = $archivePath
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Icarus Data.pak DataTable Index")
$lines.Add("")
$lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("")
$lines.Add("Source: ``$SourceDirectory``")
$lines.Add("Version label: ``$VersionLabel``")
$lines.Add("")
$lines.Add("## Counts")
$lines.Add("")
$lines.Add("- Tables: $($tableIndex.Count)")
$lines.Add("- Rows: $($rowIndex.Count)")
$lines.Add("- RowHandle links: $($links.Count)")
$lines.Add("- Missing RowHandle links: $($missingLinks.Count)")
$lines.Add("- Item connection rows: $($itemConnections.Count)")
$lines.Add("- Parse errors: $($parseErrors.Count)")
if ($archivePath) {
    $lines.Add("- Archive: ``$archivePath``")
}
$lines.Add("")
$lines.Add("## Files")
$lines.Add("")
$lines.Add("- ``datapak-table-index.csv``: table names, row structs, row counts, fields, and broad categories.")
$lines.Add("- ``datapak-row-index.csv``: every row by table, with a compact primitive summary.")
$lines.Add("- ``datapak-rowhandle-links.csv``: detected RowHandle links between tables.")
$lines.Add("- ``datapak-missing-rowhandle-links.csv``: suspicious missing target tables/rows.")
$lines.Add("- ``datapak-missing-target-rows.csv``: cleaner warning list where the target table exists but the row is absent.")
$lines.Add("- ``datapak-item-connections.csv``: D_ItemsStatic rows mapped to Meshable, Itemable, Deployable, Inventory, etc.")
$lines.Add("- ``datapak-index-manifest.json``: machine-readable build summary.")
$lines.Add("")
$lines.Add("## Search Examples")
$lines.Add("")
$lines.Add('```powershell')
$lines.Add('& ".\tools\Search-IcarusDataPakIndex.ps1" -Query "Homestead_Honey_Pot"')
$lines.Add('& ".\tools\Search-IcarusDataPakIndex.ps1" -Table D_ItemsStatic -Query "Mesh_Homestead"')
$lines.Add('& ".\tools\Search-IcarusDataPakIndex.ps1" -MissingLinksOnly -Query "Meshable"')
$lines.Add('```')
$lines | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$manifest | ConvertTo-Json -Depth 5
