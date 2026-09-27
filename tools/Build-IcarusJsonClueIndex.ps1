param(
    [string]$SourceDirectory = "",
    [string]$OutputDirectory = "",
    [int]$MaxSignalsPerCategory = 18
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $SourceDirectory) { $SourceDirectory = Join-Path $workspaceRoot "WIP json files" }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $workspaceRoot "Notes\IcarusJsonClueIndex" }

function Resolve-ObjectRefName {
    param($Json, $Index)
    if ($null -eq $Index) { return "" }
    if ($Index -isnot [int]) { return "" }
    if ($Index -lt 0) {
        $i = -$Index - 1
        if ($i -ge 0 -and $i -lt @($Json.Imports).Count) {
            return [string]$Json.Imports[$i].ObjectName
        }
    }
    elseif ($Index -gt 0) {
        $i = $Index - 1
        if ($i -ge 0 -and $i -lt @($Json.Exports).Count) {
            return [string]$Json.Exports[$i].ObjectName
        }
    }
    return ""
}

function Add-Unique {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$Value,
        [int]$Max = 40
    )
    if (-not $Value) { return }
    if ($List.Count -ge $Max) { return }
    if (-not $List.Contains($Value)) { $List.Add($Value) | Out-Null }
}

$categories = [ordered]@{
    Audio          = @("AkAudio", "Wwise", "AudioComponent", "SoundCue", "SoundBase", "TriggerSound", "PlaySound", "SFX", "Music")
    TextureVisual  = @("Texture2D", "MaterialInstance", "StaticMesh", "SkeletalMesh", "MeshComponent", "DecalComponent", "DeployableSM", "DeployableSK")
    Inventory      = @("InventoryComponent", "InventoryWidget", "BagInventory", "ContainerBase", "DeployableContainer", "SlotTemplate", "ObjectSlot", "Slotable", "D_Inventory")
    ProcessorBench = @("ProcessorBase", "ProcessorRecipes", "RecipeSet", "CraftingQueue", "CraftingBench", "Workbench", "D_Processor", "ProcessorPreview")
    ModifierAura   = @("ModifierState", "ModifierStates", "ModifierComponent", "Aura", "Buff", "Debuff", "StatusEffect", "Alteration")
    Interaction    = @("InteractableComponent", "InteractableBehaviour", "D_Interactable", "BP_Interactable", "InputAction", "ActionableBehaviour", "FocusableComponent")
    Animation      = @("AnimSequence", "AnimMontage", "AnimationAsset", "Timeline", "BlendSpace", "CurveFloat", "ActiveChanged", "StateUpdated")
    WidgetUI       = @("WidgetBlueprint", "UserWidget", "UMG_", "IcarusLinkedActorPanel", "PanelWidget", "TextBlock", "ProgressBar", "ButtonStyle")
    WaterNetwork   = @("WaterNetwork", "ResourceNetwork", "NetworkedResource", "WaterPipe", "Flow", "PowerNetwork", "ElectricNetwork", "FuelContainer", "Battery")
    DamageCombat   = @("DamageType", "DamageComponent", "HealthComponent", "Durability", "Ballistic", "Projectile", "Explosion", "Melee", "Weapon")
    TriggerOverlap = @("TriggerBox", "BoxComponent", "SphereComponent", "CapsuleComponent", "CollisionComponent", "BeginOverlap", "HitResult", "TraceChannel")
    AIQuest        = @("GOAP", "BehaviorTree", "Blackboard", "Quest", "Mission", "Objective", "NPC", "IcarusNPC")
    WeatherWorld   = @("Weather", "Lightning", "Storm", "Thermal", "Temperature", "Lava", "Snow")
    SaveReplicate  = @("Replicated", "RepNotify", "OnRep", "ActorState", "RuntimeSave", "SaveGame", "DatabaseRowHandle")
}

if (-not (Test-Path -LiteralPath $SourceDirectory)) {
    throw "Source directory not found: $SourceDirectory"
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$sourceRoot = (Resolve-Path -LiteralPath $SourceDirectory).Path.TrimEnd("\")
$files = Get-ChildItem -LiteralPath $SourceDirectory -Filter "*.json" -File -Recurse | Sort-Object FullName
$index = New-Object System.Collections.Generic.List[object]
$categoryRows = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
    $relativePath = $file.FullName
    if ($relativePath.StartsWith($sourceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativePath = $relativePath.Substring($sourceRoot.Length).TrimStart("\")
    }

    $raw = Get-Content -LiteralPath $file.FullName -Raw
    try {
        $json = $raw | ConvertFrom-Json
    }
    catch {
        $index.Add([pscustomobject]@{
            FileName = $relativePath
            Path = $file.FullName
            ParseStatus = "ERROR"
            Error = $_.Exception.Message
            SizeBytes = $file.Length
            LastWriteTime = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Categories = @()
            Signals = @()
        }) | Out-Null
        continue
    }

    $nameMap = @($json.NameMap) | Where-Object { $_ }
    $exportNames = @($json.Exports | ForEach-Object { $_.ObjectName }) | Where-Object { $_ }
    $exportTypes = @($json.Exports | ForEach-Object { $_.Type }) | Where-Object { $_ } | Select-Object -Unique
    $importNames = @($json.Imports | ForEach-Object { $_.ObjectName }) | Where-Object { $_ }
    $allNames = @($nameMap + $exportNames + $importNames) | Where-Object { $_ } | Select-Object -Unique

    $classExport = @($json.Exports | Where-Object { $_.ObjectName -match "_C$" -and $_.ObjectFlags -match "RF_Public" })[0]
    $className = ""
    $parentName = ""
    if ($classExport) {
        $className = [string]$classExport.ObjectName
        $parentName = Resolve-ObjectRefName $json $classExport.SuperStruct
        if (-not $parentName) { $parentName = Resolve-ObjectRefName $json $classExport.SuperIndex }
    }

    $matchedCategories = New-Object System.Collections.Generic.List[string]
    $signalsByCategory = [ordered]@{}
    foreach ($category in $categories.Keys) {
        $signals = New-Object System.Collections.Generic.List[string]
        $categorySearchNames = @($file.Name, $className, $parentName) + $allNames
        foreach ($term in $categories[$category]) {
            $pattern = [regex]::Escape($term)
            foreach ($name in $categorySearchNames) {
                if ($name -match $pattern) {
                    Add-Unique $signals $name $MaxSignalsPerCategory
                }
            }
        }
        if ($signals.Count -gt 0) {
            $matchedCategories.Add($category) | Out-Null
            $signalsByCategory[$category] = @($signals)
            $categoryRows.Add([pscustomobject]@{
                Category = $category
                FileName = $relativePath
                BlueprintClass = $className
                Parent = $parentName
                Signals = (@($signals) -join "; ")
            }) | Out-Null
        }
    }

    $interesting = New-Object System.Collections.Generic.List[string]
    foreach ($name in $allNames) {
        if ($name -match "Interact|Audio|Sound|Inventory|Processor|Recipe|Modifier|Aura|Trigger|Overlap|Timeline|Widget|Water|Network|Damage|Ballistic|Quest|GOAP|Lightning|Weather|OnRep") {
            Add-Unique $interesting $name 60
        }
    }

    $index.Add([pscustomobject]@{
        FileName = $relativePath
        Path = $file.FullName
        ParseStatus = "OK"
        SizeBytes = $file.Length
        LastWriteTime = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        BlueprintClass = $className
        Parent = $parentName
        ExportTypes = @($exportTypes)
        ExportCount = @($json.Exports).Count
        ImportCount = @($json.Imports).Count
        Categories = @($matchedCategories)
        SignalsByCategory = $signalsByCategory
        InterestingNames = @($interesting)
    }) | Out-Null
}

$indexPath = Join-Path $OutputDirectory "icarus-json-clue-index.json"
$csvPath = Join-Path $OutputDirectory "icarus-json-clue-index.csv"
$categoryCsvPath = Join-Path $OutputDirectory "icarus-json-category-map.csv"
$summaryPath = Join-Path $OutputDirectory "README.md"

$index | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $indexPath -Encoding UTF8
$index |
    Select-Object FileName,ParseStatus,BlueprintClass,Parent,
        @{Name="Categories";Expression={@($_.Categories) -join "; "}},
        @{Name="InterestingNames";Expression={@($_.InterestingNames) -join "; "}},
        SizeBytes,LastWriteTime,Path |
    Export-Csv -LiteralPath $csvPath -NoTypeInformation
$categoryRows | Export-Csv -LiteralPath $categoryCsvPath -NoTypeInformation

$okCount = @($index | Where-Object ParseStatus -eq "OK").Count
$errorCount = @($index | Where-Object ParseStatus -ne "OK").Count
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Icarus JSON Clue Index")
$lines.Add("")
$lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("")
$lines.Add("Source: ``$SourceDirectory``")
$lines.Add("")
$lines.Add("Files indexed: $($index.Count)")
$lines.Add("Parsed: $okCount")
$lines.Add("Parse errors: $errorCount")
$lines.Add("")
$lines.Add("## Files")
$lines.Add("")
$lines.Add("- Full JSON index: ``icarus-json-clue-index.json``")
$lines.Add("- Spreadsheet-friendly index: ``icarus-json-clue-index.csv``")
$lines.Add("- Category-to-file map: ``icarus-json-category-map.csv``")
$lines.Add("")
$lines.Add("## Category Counts")
$lines.Add("")
foreach ($category in $categories.Keys) {
    $count = @($categoryRows | Where-Object Category -eq $category).Count
    $lines.Add("- ${category}: $count")
}
$lines.Add("")
$lines.Add("## Handy Search Examples")
$lines.Add("")
$lines.Add('```powershell')
$lines.Add('& ".\tools\Search-IcarusJsonClueIndex.ps1" -Query "trigger sound"')
$lines.Add('& ".\tools\Search-IcarusJsonClueIndex.ps1" -Category Audio')
$lines.Add('& ".\tools\Search-IcarusJsonClueIndex.ps1" -Query "lightning"')
$lines.Add('```')
$lines | Set-Content -LiteralPath $summaryPath -Encoding UTF8

[pscustomobject]@{
    SourceDirectory = $SourceDirectory
    OutputDirectory = $OutputDirectory
    FilesIndexed = $index.Count
    Parsed = $okCount
    ParseErrors = $errorCount
    IndexPath = $indexPath
    CsvPath = $csvPath
    CategoryCsvPath = $categoryCsvPath
    SummaryPath = $summaryPath
} | ConvertTo-Json -Depth 4
