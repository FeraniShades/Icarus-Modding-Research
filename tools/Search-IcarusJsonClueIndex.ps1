param(
    [string]$Query = "",

    [string]$Category = "",

    [string]$IndexPath = "",

    [int]$Top = 25,

    [switch]$Detailed,

    [switch]$ShowNames
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $IndexPath) { $IndexPath = Join-Path $workspaceRoot "Notes\IcarusJsonClueIndex\icarus-json-clue-index.json" }

function Shorten-ListText {
    param(
        [string]$Text,
        [int]$Length = 70
    )
    if (-not $Text) { return "" }
    if ($Text.Length -le $Length) { return $Text }
    return "$($Text.Substring(0, $Length - 3))..."
}

if (-not (Test-Path -LiteralPath $IndexPath)) {
    throw "Index not found: $IndexPath. Build it first with Build-IcarusJsonClueIndex.ps1."
}

$index = Get-Content -LiteralPath $IndexPath -Raw | ConvertFrom-Json
$terms = @($Query -split "\s+" | Where-Object { $_ })

$results = foreach ($entry in @($index)) {
    if ($entry.ParseStatus -ne "OK") { continue }
    if ($Category -and (@($entry.Categories) -notcontains $Category)) { continue }

    $haystackParts = @(
        $entry.FileName
        $entry.BlueprintClass
        $entry.Parent
        (@($entry.Categories) -join " ")
        (@($entry.InterestingNames) -join " ")
        ($entry.SignalsByCategory | ConvertTo-Json -Compress -Depth 8)
    )
    $haystack = ($haystackParts -join " ")

    $score = 0
    $hits = New-Object System.Collections.Generic.List[string]

    foreach ($term in $terms) {
        $pattern = [regex]::Escape($term)
        if ($entry.FileName -match $pattern) {
            $score += 8
            if (-not $hits.Contains("file:$term")) { $hits.Add("file:$term") | Out-Null }
        }
        if ($entry.BlueprintClass -match $pattern -or $entry.Parent -match $pattern) {
            $score += 6
            if (-not $hits.Contains("class:$term")) { $hits.Add("class:$term") | Out-Null }
        }
        foreach ($categoryName in @($entry.Categories)) {
            if ($categoryName -match $pattern) {
                $score += 5
                if (-not $hits.Contains("category:$categoryName")) { $hits.Add("category:$categoryName") | Out-Null }
            }
        }
        foreach ($name in @($entry.InterestingNames)) {
            if ($name -match $pattern) {
                $score += 3
                if ($hits.Count -lt 12 -and -not $hits.Contains($name)) { $hits.Add($name) | Out-Null }
            }
        }
        if ($haystack -match $pattern) {
            $score += 1
            if ($hits.Count -lt 12 -and -not $hits.Contains($term)) { $hits.Add($term) | Out-Null }
        }
    }

    if (-not $terms -or $score -gt 0) {
        if ($Category) {
            $score += 1
        }
        $categoriesText = (@($entry.Categories) -join "; ")
        [pscustomobject]@{
            Score = $score
            FileName = $entry.FileName
            BlueprintClass = $entry.BlueprintClass
            Parent = $entry.Parent
            Categories = Shorten-ListText $categoriesText
            Hits = Shorten-ListText ((@($hits) -join "; "))
            InterestingNames = ((@($entry.InterestingNames) | Select-Object -First 18) -join "; ")
            Path = $entry.Path
            SignalsByCategory = $entry.SignalsByCategory
        }
    }
}

$sorted = @(
    $results |
        Sort-Object @{ Expression = "Score"; Descending = $true }, FileName |
        Select-Object -First $Top
)

if ($Detailed) {
    $sorted | ConvertTo-Json -Depth 10
}
else {
    foreach ($item in $sorted) {
        Write-Output ("[{0}] {1}" -f $item.Score, $item.FileName)
        if ($item.BlueprintClass -or $item.Parent) {
            Write-Output ("    Class: {0}    Parent: {1}" -f $item.BlueprintClass, $item.Parent)
        }
        if ($item.Categories) {
            Write-Output ("    Categories: {0}" -f $item.Categories)
        }
        if ($item.Hits) {
            Write-Output ("    Hits: {0}" -f $item.Hits)
        }
        if ($ShowNames -and $item.InterestingNames) {
            Write-Output ("    Names: {0}" -f (Shorten-ListText $item.InterestingNames 120))
        }
        Write-Output ""
    }
}
