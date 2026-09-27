param(
    [string]$SeedPath = "",
    [string]$OutputDirectory = "",
    [string]$SourceName = "ICARUS Wiki",
    [string]$ApiBase = "https://icarus.wiki.gg/api.php",
    [int]$MaxNotesPerPage = 12,
    [switch]$AllowEmpty
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $workspaceRoot "Notes\IcarusGameplayClueIndex" }
if (-not $SeedPath) { $SeedPath = Join-Path $OutputDirectory "wiki-page-seeds.txt" }

$tagRules = [ordered]@{
    FoodSpoilage      = @("food", "stomach", "consume", "spoil", "spoiled", "buff", "nutrition")
    CraftingBench     = @("craft", "recipe", "bench", "processor", "queue", "tier", "blueprint")
    StorageInventory  = @("storage", "inventory", "slot", "container", "pouch", "bag")
    Deployable        = @("deployable", "place", "pickup", "interact", "device", "station")
    WaterNetwork      = @("water", "pipe", "network", "flow", "irrigation", "pump")
    ElectricityFuel   = @("electric", "power", "generator", "battery", "fuel", "biofuel")
    WeatherWorld      = @("weather", "storm", "lightning", "temperature", "cave", "underground")
    AnimalHusbandry   = @("animal", "tamed", "mount", "feed", "husbandry", "gestation", "phenotype")
    CombatDamage      = @("weapon", "projectile", "damage", "ammo", "reload", "ballistic", "grenade")
    MissionQuest      = @("mission", "quest", "objective", "hint", "prospect", "outpost")
    DLCGateRisk       = @("dlc", "expansion", "homestead", "dangerous horizons", "new frontiers")
}

$moddingHints = [ordered]@{
    "food|stomach|consume|spoil|buff|nutrition" = @("D_ItemsStatic", "D_Itemable", "D_ModifierStates", "D_Inventory", "SlotTemplates")
    "craft|recipe|bench|processor|queue|blueprint" = @("D_ProcessorRecipes", "D_Crafting", "D_Deployable", "D_ItemsStatic")
    "storage|inventory|slot|container|pouch|bag" = @("D_Inventory", "D_Deployable", "D_Itemable", "BP_DeployableContainerBase")
    "water|pipe|network|flow|pump" = @("D_Deployable", "D_ResourceNetwork", "BP_ResourceNetworkProcessor")
    "electric|power|generator|battery|fuel|biofuel" = @("D_Deployable", "D_ProcessorRecipes", "D_ItemsStatic", "BP_ResourceNetworkProcessor")
    "weather|storm|lightning|temperature" = @("D_WeatherEvents", "D_ModifierStates", "BP_LightningRod_Base", "BP_DisasterController")
    "animal|tamed|mount|feed|husbandry|gestation|phenotype" = @("D_AISetup", "D_Talents", "D_ItemsStatic", "D_ProcessorRecipes")
    "weapon|projectile|damage|ammo|reload|ballistic|grenade" = @("D_ItemsStatic", "D_Stats", "D_Ammo", "D_DamageTypes", "BP_ActionableBehaviour")
    "mission|quest|objective|hint|prospect" = @("D_Quest", "D_ProspectList", "D_Missions", "D_Text")
    "dlc|expansion|homestead|dangerous horizons|new frontiers" = @("D_DLCPackageData", "RequiredFlags", "SessionRequirement")
}

function ConvertTo-Slug {
    param([string]$Title)
    $slug = $Title -replace "[^\w\-]+", "_"
    $slug = $slug.Trim("_")
    if (-not $slug) { return "page" }
    return $slug
}

function Get-PlainTextPage {
    param([string]$Title)

    $encodedTitle = [uri]::EscapeDataString($Title)
    $url = "${ApiBase}?action=query&prop=extracts&explaintext=1&exsectionformat=plain&redirects=1&format=json&titles=$encodedTitle"
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{ "User-Agent" = "Ferani-Icarus-Modding-Notes/1.0" }
    $page = $response.query.pages.PSObject.Properties.Value | Select-Object -First 1

    $extract = [string]$page.extract
    if ($page.pageid -and $extract.Trim().Length -lt 30) {
        $parseUrl = "${ApiBase}?action=parse&prop=text&redirects=1&format=json&page=$encodedTitle"
        $parseResponse = Invoke-RestMethod -Uri $parseUrl -Method Get -Headers @{ "User-Agent" = "Ferani-Icarus-Modding-Notes/1.0" }
        $html = [string]$parseResponse.parse.text.'*'
        if ($html) {
            $extract = Convert-HtmlToPlainText $html
        }
    }

    [pscustomobject]@{
        Title = [string]$page.title
        PageId = [string]$page.pageid
        Extract = $extract
    }
}

function Convert-HtmlToPlainText {
    param([string]$Html)
    $text = $Html
    $text = [regex]::Replace($text, "(?is)<script.*?</script>", " ")
    $text = [regex]::Replace($text, "(?is)<style.*?</style>", " ")
    $text = [regex]::Replace($text, "(?is)<table.*?</table>", " ")
    $text = [regex]::Replace($text, "(?i)<br\s*/?>", "`n")
    $text = [regex]::Replace($text, "(?i)</p>|</li>|</h[1-6]>", "`n")
    $text = [regex]::Replace($text, "<[^>]+>", " ")
    $text = [System.Net.WebUtility]::HtmlDecode($text)
    $text = [regex]::Replace($text, "[`t ]+", " ")
    $text = [regex]::Replace($text, " ?`r?`n ?", "`n")
    $text = [regex]::Replace($text, "`n{3,}", "`n`n")
    return $text.Trim()
}

function Get-Tags {
    param([string]$Text)
    $tags = New-Object System.Collections.Generic.List[string]
    foreach ($tag in $tagRules.Keys) {
        foreach ($term in $tagRules[$tag]) {
            if ($Text -match [regex]::Escape($term)) {
                if (-not $tags.Contains($tag)) { $tags.Add($tag) | Out-Null }
                break
            }
        }
    }
    return @($tags)
}

function Get-Hints {
    param([string]$Text)
    $hints = New-Object System.Collections.Generic.List[string]
    foreach ($pattern in $moddingHints.Keys) {
        if ($Text -match $pattern) {
            foreach ($hint in $moddingHints[$pattern]) {
                if (-not $hints.Contains($hint)) { $hints.Add($hint) | Out-Null }
            }
        }
    }
    return @($hints)
}

function Get-KeyLines {
    param([string]$Text)
    $keywords = "craft|recipe|bench|processor|storage|inventory|slot|spoil|buff|consume|water|network|electric|fuel|lightning|weather|animal|tamed|mount|damage|projectile|mission|dlc|expansion"
    $lines = @(
        $Text -split "`r?`n" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and $_.Length -ge 20 -and $_ -match $keywords } |
            Select-Object -First $MaxNotesPerPage
    )
    return @($lines)
}

function Get-ExistingFeraniNotes {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @("- ") }

    $content = Get-Content -LiteralPath $Path -Raw
    $match = [regex]::Match($content, "(?s)## Ferani Notes\s*(.*)$")
    if (-not $match.Success) { return @("- ") }

    $notes = @($match.Groups[1].Value.TrimEnd() -split "`r?`n")
    if ($notes.Count -eq 0 -or -not ($notes -join "").Trim()) { return @("- ") }
    return $notes
}

if (-not (Test-Path -LiteralPath $SeedPath)) {
    throw "Seed file not found: $SeedPath"
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutputDirectory "pages") | Out-Null

$titles = @(
    Get-Content -LiteralPath $SeedPath |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith("#") } |
        Select-Object -Unique
)

$index = New-Object System.Collections.Generic.List[object]
$errors = New-Object System.Collections.Generic.List[object]

foreach ($title in $titles) {
    try {
        $page = Get-PlainTextPage $title
        if (-not $page.PageId) {
            throw "Page not found"
        }

        $text = $page.Extract
        $tags = Get-Tags $text.ToLowerInvariant()
        $hints = Get-Hints $text.ToLowerInvariant()
        $keyLines = Get-KeyLines $text
        $urlTitle = $page.Title -replace " ", "_"
        $url = "https://icarus.wiki.gg/wiki/$urlTitle"
        $slug = ConvertTo-Slug $page.Title
        $notePath = Join-Path $OutputDirectory ("pages\$slug.md")
        $existingFeraniNotes = Get-ExistingFeraniNotes $notePath

        $noteLines = New-Object System.Collections.Generic.List[string]
        $noteLines.Add("# $($page.Title)")
        $noteLines.Add("")
        $noteLines.Add("- Source: $SourceName")
        $noteLines.Add("- URL: $url")
        $noteLines.Add("- Indexed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        $noteLines.Add("- Tags: $(@($tags) -join ', ')")
        $noteLines.Add("- Likely modding tables/files: $(@($hints) -join ', ')")
        $noteLines.Add("")
        $noteLines.Add("## Gameplay Clues")
        $noteLines.Add("")
        if ($keyLines.Count -gt 0) {
            foreach ($line in $keyLines) {
                $noteLines.Add("- $line")
            }
        }
        else {
            $noteLines.Add("- Add manual notes here after reviewing the source page.")
        }
        $noteLines.Add("")
        $noteLines.Add("## Ferani Notes")
        $noteLines.Add("")
        foreach ($line in $existingFeraniNotes) {
            $noteLines.Add($line)
        }
        $noteLines | Set-Content -LiteralPath $notePath -Encoding UTF8

        $index.Add([pscustomobject]@{
            Title = $page.Title
            Source = $SourceName
            Url = $url
            IndexedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Tags = @($tags)
            LikelyModdingTargets = @($hints)
            KeyLines = @($keyLines)
            NotePath = $notePath
        }) | Out-Null
    }
    catch {
        $errors.Add([pscustomobject]@{
            Title = $title
            Error = $_.Exception.Message
        }) | Out-Null
    }
}

$indexPath = Join-Path $OutputDirectory "icarus-gameplay-clue-index.json"
$csvPath = Join-Path $OutputDirectory "icarus-gameplay-clue-index.csv"
$readmePath = Join-Path $OutputDirectory "README.md"

if ($index.Count -eq 0 -and $errors.Count -gt 0 -and -not $AllowEmpty) {
    throw "No pages were indexed. Existing index files were left untouched. Check network access or run with -AllowEmpty if you really want empty outputs."
}

$index | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $indexPath -Encoding UTF8
$index |
    Select-Object Title,Source,Url,
        @{Name="Tags";Expression={@($_.Tags) -join "; "}},
        @{Name="LikelyModdingTargets";Expression={@($_.LikelyModdingTargets) -join "; "}},
        NotePath |
    Export-Csv -LiteralPath $csvPath -NoTypeInformation

$readme = New-Object System.Collections.Generic.List[string]
$readme.Add("# Icarus Gameplay Clue Index")
$readme.Add("")
$readme.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$readme.Add("")
$readme.Add("This is a compact reference index for gameplay-facing ICARUS wiki notes. It stores links, tags, short clues, likely modding targets, and a human-editable note file per page. It is intentionally not a full wiki mirror.")
$readme.Add("")
$readme.Add("## Files")
$readme.Add("")
$readme.Add("- ``icarus-gameplay-clue-index.json``")
$readme.Add("- ``icarus-gameplay-clue-index.csv``")
$readme.Add("- ``wiki-page-seeds.txt``")
$readme.Add("- ``pages\\*.md``")
$readme.Add("- ``changelogs\\*.md``")
$readme.Add("")
$readme.Add("## Search Examples")
$readme.Add("")
$readme.Add('```powershell')
$readme.Add('& ".\tools\Search-IcarusGameplayClueIndex.ps1" -Query "spoil"')
$readme.Add('& ".\tools\Search-IcarusGameplayClueIndex.ps1" -Tag CraftingBench')
$readme.Add('& ".\tools\Search-IcarusGameplayClueIndex.ps1" -Query "lightning water network"')
$readme.Add('```')
$readme.Add("")
$readme.Add("## Indexed Pages")
$readme.Add("")
foreach ($entry in $index) {
    $readme.Add("- [$($entry.Title)]($($entry.Url))")
}
if ($errors.Count -gt 0) {
    $readme.Add("")
    $readme.Add("## Fetch Errors")
    $readme.Add("")
    foreach ($err in $errors) {
        $readme.Add("- $($err.Title): $($err.Error)")
    }
}
$readme | Set-Content -LiteralPath $readmePath -Encoding UTF8

[pscustomobject]@{
    SeedPath = $SeedPath
    OutputDirectory = $OutputDirectory
    PagesRequested = $titles.Count
    PagesIndexed = $index.Count
    Errors = $errors.Count
    IndexPath = $indexPath
    CsvPath = $csvPath
    ReadmePath = $readmePath
} | ConvertTo-Json -Depth 4
