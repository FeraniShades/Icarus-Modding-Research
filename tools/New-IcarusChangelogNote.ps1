param(
    [string]$OutputDirectory = "",
    [string]$Title = "",
    [string]$SourceUrl = "",
    [string]$Date = (Get-Date -Format "yyyy-MM-dd")
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $workspaceRoot "Notes\IcarusGameplayClueIndex\changelogs" }

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

if (-not $Title) {
    $Title = "ICARUS Changelog $Date"
}

$slug = ($Title -replace "[^\w\-]+", "_").Trim("_")
if (-not $slug) { $slug = "ICARUS_Changelog_$Date" }

$path = Join-Path $OutputDirectory "$Date-$slug.md"

if (Test-Path -LiteralPath $path) {
    throw "Changelog note already exists: $path"
}

$lines = @(
    "# $Title",
    "",
    "- Date reviewed: $Date",
    "- Source URL: $SourceUrl",
    "- Game version/build: ",
    "- Reviewed by: ",
    "",
    "## Modding Impact Summary",
    "",
    "- ",
    "",
    "## Systems To Recheck",
    "",
    "- [ ] Homestead Expanded storage containers",
    "- [ ] Butter Churn / processor recipes",
    "- [ ] Spinning Wheel / processor recipes",
    "- [ ] DLC gates: D_DLCPackageData / RequiredFlags / SessionRequirement",
    "- [ ] Weather Vane / lightning rod behavior",
    "- [ ] Well / water network behavior",
    "- [ ] Silo slot validation, spoilage, and feed categories",
    "",
    "## Changed Gameplay Areas",
    "",
    "- Items/resources:",
    "- Recipes/processors:",
    "- Talents/buffs/modifiers:",
    "- Deployables/BPs:",
    "- UI/widgets:",
    "- Animals/farming:",
    "- Weather/world systems:",
    "- Missions/prospects/DLC/session gates:",
    "",
    "## Files Or Tables Worth Checking",
    "",
    "- ",
    "",
    "## Exact Patch Notes Excerpts",
    "",
    "> Keep this short. Link to the full changelog above rather than copying the whole thing.",
    "",
    "## Follow-Up Tests",
    "",
    "- [ ] "
)

$lines | Set-Content -LiteralPath $path -Encoding UTF8

[pscustomobject]@{
    Path = $path
    Title = $Title
    SourceUrl = $SourceUrl
    Date = $Date
} | ConvertTo-Json -Depth 4
