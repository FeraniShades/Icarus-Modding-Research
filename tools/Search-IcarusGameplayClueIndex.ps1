param(
    [string]$Query = "",
    [string]$Tag = "",
    [string]$IndexPath = "",
    [int]$Top = 20,
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $IndexPath) { $IndexPath = Join-Path $workspaceRoot "Notes\IcarusGameplayClueIndex\icarus-gameplay-clue-index.json" }

function Shorten-Text {
    param(
        [string]$Text,
        [int]$Length = 140
    )
    if (-not $Text) { return "" }
    if ($Text.Length -le $Length) { return $Text }
    return "$($Text.Substring(0, $Length - 3))..."
}

if (-not (Test-Path -LiteralPath $IndexPath)) {
    throw "Index not found: $IndexPath. Build it first with Build-IcarusGameplayClueIndex.ps1."
}

$index = Get-Content -LiteralPath $IndexPath -Raw | ConvertFrom-Json
$terms = @($Query -split "\s+" | Where-Object { $_ })

$results = foreach ($entry in @($index)) {
    if ($Tag -and (@($entry.Tags) -notcontains $Tag)) { continue }

    $haystack = @(
        $entry.Title
        $entry.Url
        (@($entry.Tags) -join " ")
        (@($entry.LikelyModdingTargets) -join " ")
        (@($entry.KeyLines) -join " ")
    ) -join " "

    $score = 0
    $hits = New-Object System.Collections.Generic.List[string]

    foreach ($term in $terms) {
        $pattern = [regex]::Escape($term)
        if ($entry.Title -match $pattern) {
            $score += 8
            $hits.Add("title:$term") | Out-Null
        }
        foreach ($tagName in @($entry.Tags)) {
            if ($tagName -match $pattern) {
                $score += 5
                $hits.Add("tag:$tagName") | Out-Null
            }
        }
        foreach ($target in @($entry.LikelyModdingTargets)) {
            if ($target -match $pattern) {
                $score += 4
                $hits.Add("target:$target") | Out-Null
            }
        }
        if ($haystack -match $pattern) {
            $score += 1
            if ($hits.Count -lt 10) { $hits.Add($term) | Out-Null }
        }
    }

    if (-not $terms -or $score -gt 0 -or $Tag) {
        if ($Tag) { $score += 1 }
        [pscustomobject]@{
            Score = $score
            Title = $entry.Title
            Tags = (@($entry.Tags) -join "; ")
            LikelyModdingTargets = (@($entry.LikelyModdingTargets) -join "; ")
            Hits = (@($hits | Select-Object -Unique) -join "; ")
            FirstClue = (@($entry.KeyLines) | Select-Object -First 1)
            Url = $entry.Url
            NotePath = $entry.NotePath
        }
    }
}

$sorted = @(
    $results |
        Sort-Object @{ Expression = "Score"; Descending = $true }, Title |
        Select-Object -First $Top
)

if ($Detailed) {
    $sorted | ConvertTo-Json -Depth 8
}
else {
    foreach ($item in $sorted) {
        Write-Output ("[{0}] {1}" -f $item.Score, $item.Title)
        if ($item.Tags) {
            Write-Output ("    Tags: {0}" -f (Shorten-Text $item.Tags 100))
        }
        if ($item.LikelyModdingTargets) {
            Write-Output ("    Likely modding targets: {0}" -f (Shorten-Text $item.LikelyModdingTargets 110))
        }
        if ($item.Hits) {
            Write-Output ("    Hits: {0}" -f (Shorten-Text $item.Hits 110))
        }
        if ($item.FirstClue) {
            Write-Output ("    Clue: {0}" -f (Shorten-Text $item.FirstClue 170))
        }
        Write-Output ("    URL: {0}" -f $item.Url)
        Write-Output ("    Note: {0}" -f $item.NotePath)
        Write-Output ""
    }
}
