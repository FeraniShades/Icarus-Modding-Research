param(
    [string]$GameDataRoot = "",
    [Parameter(Mandatory = $true)]
    [string]$ModPath,
    [string]$ReportPath = "",
    [switch]$JsonOnly
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $GameDataRoot) { $GameDataRoot = Join-Path $workspaceRoot "data" }

function Read-JsonFile {
    param([string]$Path)
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-RowMap {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @{}
    }

    $json = Read-JsonFile $Path
    $map = @{}
    foreach ($row in @($json.Rows)) {
        if ($row.Name) {
            $map[$row.Name] = $row
        }
    }
    return $map
}

function Get-Feature {
    param($Row)
    if ($null -eq $Row) { return "" }
    $feature = $Row.Metadata.RequiredFeatureLevel.RowName
    if ($feature) { return [string]$feature }
    return ""
}

function Get-RequiredPackage {
    param($Row)
    if ($null -eq $Row) { return "" }
    if ($Row.SessionRequirement -and $Row.SessionRequirement.DataTableName -eq "D_DLCPackageData" -and $Row.SessionRequirement.RowName) {
        return [string]$Row.SessionRequirement.RowName
    }
    foreach ($flag in @($Row.RequiredFlags)) {
        if ($flag.DataTableName -eq "D_DLCPackageData" -and $flag.RowName) {
            return [string]$flag.RowName
        }
    }
    foreach ($name in @("RequiredPackageToPurchase", "RequiredPackage", "RequiredDLCPackage", "DLCPackage")) {
        $prop = $Row.PSObject.Properties[$name]
        if ($prop -and $prop.Value.RowName) {
            return [string]$prop.Value.RowName
        }
    }
    return ""
}

function Get-RefFeature {
    param(
        [hashtable]$Tables,
        [string]$TableName,
        [string]$RowName
    )
    if (-not $RowName -or $RowName -eq "None") { return "" }
    if (-not $Tables.ContainsKey($TableName)) { return "" }
    return Get-Feature $Tables[$TableName][$RowName]
}

function Get-RowRef {
    param($Obj)
    if ($null -eq $Obj) { return $null }
    if ($Obj.RowName) {
        return [pscustomobject]@{
            RowName = [string]$Obj.RowName
            DataTableName = [string]$Obj.DataTableName
        }
    }
    return $null
}

function Add-Finding {
    param(
        [System.Collections.Generic.List[object]]$Findings,
        [string]$Severity,
        [string]$Table,
        [string]$Row,
        [string]$Field,
        [string]$Message,
        [string]$Feature = "",
        [string]$Reference = ""
    )

    $Findings.Add([pscustomobject]@{
        Severity = $Severity
        Table = $Table
        Row = $Row
        Field = $Field
        Feature = $Feature
        Reference = $Reference
        Message = $Message
    }) | Out-Null
}

function Get-DataTablePath {
    param([string]$Root, [string]$TableName)
    $match = Get-ChildItem -LiteralPath $Root -Recurse -Filter "$TableName.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($match) { return $match.FullName }
    return ""
}

function Convert-CurrentFileToTableName {
    param([string]$CurrentFile)
    if (-not $CurrentFile) { return "" }
    $name = [IO.Path]::GetFileNameWithoutExtension($CurrentFile)
    $dash = $name.LastIndexOf("-")
    if ($dash -ge 0) {
        return $name.Substring($dash + 1)
    }
    return $name
}

function Load-ModRows {
    param([string]$Path)

    $tables = @{}
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $json = Read-JsonFile $Path
        foreach ($entry in @($json.Rows)) {
            $table = Convert-CurrentFileToTableName $entry.CurrentFile
            if (-not $table) { continue }
            if (-not $tables.ContainsKey($table)) {
                $tables[$table] = New-Object System.Collections.Generic.List[object]
            }
            foreach ($row in @($entry.File_Items)) {
                if ($row.Name) { $tables[$table].Add($row) | Out-Null }
            }
        }
    }
    elseif (Test-Path -LiteralPath $Path -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $Path -Recurse -Filter "D_*.json" -File) {
            $table = [IO.Path]::GetFileNameWithoutExtension($file.Name)
            $json = Read-JsonFile $file.FullName
            if (-not $tables.ContainsKey($table)) {
                $tables[$table] = New-Object System.Collections.Generic.List[object]
            }
            foreach ($row in @($json.Rows)) {
                if ($row.Name) { $tables[$table].Add($row) | Out-Null }
            }
        }
    }
    else {
        throw "ModPath does not exist: $Path"
    }

    return $tables
}

function Test-SameOrStrongerGate {
    param(
        [string]$SourceFeature,
        [string]$TargetFeature,
        [string]$SourcePackage,
        [hashtable]$PackageFeatureMap
    )

    if (-not $TargetFeature) { return $true }
    if ($SourcePackage -and $PackageFeatureMap.ContainsKey($SourcePackage) -and $PackageFeatureMap[$SourcePackage] -eq $TargetFeature) {
        return $true
    }
    return $false
}

function Find-AssetFeatureHint {
    param([string]$Value)
    if (-not $Value) { return "" }
    if ($Value -match "Homestead|Honey_Jar|DCO/") { return "Homestead" }
    if ($Value -match "GreatHunt|Great_Hunt|Biolab|GH_") { return "GreatHunts" }
    if ($Value -match "DangerousHorizons|Terrain_021_DLC2|DLC2") { return "DangerousHorizons" }
    if ($Value -match "NewFrontiers|Terrain_019_DLC|DLC1") { return "NewFrontiers" }
    if ($Value -match "Laika|T_ICON_Paws|Pet_|Creature_Comforts") { return "Laika" }
    return ""
}

$coreTables = @(
    "D_ItemsStatic",
    "D_ItemTemplate",
    "D_RecipeSets",
    "D_ProcessorRecipes",
    "D_DeployableSetup",
    "D_Deployable",
    "D_Inventory",
    "D_InventoryInfo",
    "D_Talents",
    "D_BlueprintUnlocks",
    "D_WorkshopItems",
    "D_LivingItemShopItems",
    "D_ItemRewards",
    "D_DynamicQuestRewardItems",
    "D_DLCPackageData"
)

$baseTables = @{}
foreach ($table in $coreTables) {
    $path = Get-DataTablePath $GameDataRoot $table
    if ($path) {
        $baseTables[$table] = Get-RowMap $path
    }
}

$packageFeatureMap = @{}
if ($baseTables.ContainsKey("D_DLCPackageData")) {
    foreach ($key in $baseTables["D_DLCPackageData"].Keys) {
        $feature = Get-Feature $baseTables["D_DLCPackageData"][$key]
        if ($feature) {
            $packageFeatureMap[$key] = $feature
        }
    }
}

$modTables = Load-ModRows $ModPath
$findings = New-Object System.Collections.Generic.List[object]

foreach ($tableName in $modTables.Keys) {
    $modRowsForTable = @()
    foreach ($entry in $modTables[$tableName]) {
        $modRowsForTable += $entry
    }

    foreach ($row in $modRowsForTable) {
        $rowFeature = Get-Feature $row
        $rowPackage = Get-RequiredPackage $row

        if ($rowFeature) {
            Add-Finding $findings "INFO" $tableName $row.Name "Metadata.RequiredFeatureLevel" "Row has feature-level/version metadata. This is not a DLC ownership gate." $rowFeature ""
        }

        if ($rowPackage) {
            $packageFeature = ""
            if ($packageFeatureMap.ContainsKey($rowPackage)) { $packageFeature = $packageFeatureMap[$rowPackage] }
            Add-Finding $findings "INFO" $tableName $row.Name "DLCGate" "Row has an explicit DLC/account package gate." $packageFeature $rowPackage
        }

        switch ($tableName) {
            "D_ProcessorRecipes" {
                foreach ($output in @($row.Outputs)) {
                    $ref = Get-RowRef $output.Element
                    if (-not $ref) { continue }
                    $targetTable = if ($ref.DataTableName) { $ref.DataTableName } else { "D_ItemsStatic" }
                    $targetFeature = Get-RefFeature $baseTables $targetTable $ref.RowName
                    if (-not (Test-SameOrStrongerGate $rowFeature $targetFeature $rowPackage $packageFeatureMap)) {
                        Add-Finding $findings "ERROR" $tableName $row.Name "Outputs.Element" "Recipe outputs a DLC/feature-scoped item but this recipe row is not gated to the same feature/package." $targetFeature "$targetTable.$($ref.RowName)"
                    }
                }

                foreach ($setRef in @($row.RecipeSets)) {
                    $setFeature = Get-RefFeature $baseTables "D_RecipeSets" $setRef.RowName
                    if ($setFeature -and -not $rowFeature) {
                        Add-Finding $findings "INFO" $tableName $row.Name "RecipeSets" "Recipe uses a feature-scoped recipe set; this may be the intended gate." $setFeature "D_RecipeSets.$($setRef.RowName)"
                    }
                }
            }

            "D_WorkshopItems" {
                $ref = Get-RowRef $row.Item
                if ($ref) {
                    $targetFeature = Get-RefFeature $baseTables "D_ItemsStatic" $ref.RowName
                    if (-not (Test-SameOrStrongerGate $rowFeature $targetFeature $rowPackage $packageFeatureMap)) {
                        Add-Finding $findings "ERROR" $tableName $row.Name "Item" "Workshop row grants a DLC/feature-scoped item without a matching feature/package gate." $targetFeature "D_ItemsStatic.$($ref.RowName)"
                    }
                }
            }

            "D_LivingItemShopItems" {
                $ref = Get-RowRef $row.ItemTemplate
                if ($ref) {
                    $targetFeature = Get-RefFeature $baseTables "D_ItemTemplate" $ref.RowName
                    if (-not (Test-SameOrStrongerGate $rowFeature $targetFeature $rowPackage $packageFeatureMap)) {
                        Add-Finding $findings "ERROR" $tableName $row.Name "ItemTemplate" "Living-item shop row references a DLC/feature-scoped item template without a matching feature/package gate." $targetFeature "D_ItemTemplate.$($ref.RowName)"
                    }
                }
            }

            "D_ItemRewards" {
                foreach ($reward in @($row.Rewards)) {
                    $ref = Get-RowRef $reward.Item
                    if (-not $ref) { continue }
                    $targetTable = if ($ref.DataTableName) { $ref.DataTableName } else { "D_ItemsStatic" }
                    $targetFeature = Get-RefFeature $baseTables $targetTable $ref.RowName
                    if (-not (Test-SameOrStrongerGate $rowFeature $targetFeature $rowPackage $packageFeatureMap)) {
                        Add-Finding $findings "ERROR" $tableName $row.Name "Rewards.Item" "Reward row can grant a DLC/feature-scoped item without a matching feature/package gate." $targetFeature "$targetTable.$($ref.RowName)"
                    }
                }
            }

            "D_DynamicQuestRewardItems" {
                foreach ($reward in @($row.Rewards)) {
                    $ref = Get-RowRef $reward.Item
                    if (-not $ref) { continue }
                    $targetTable = if ($ref.DataTableName) { $ref.DataTableName } else { "D_ItemsStatic" }
                    $targetFeature = Get-RefFeature $baseTables $targetTable $ref.RowName
                    if (-not (Test-SameOrStrongerGate $rowFeature $targetFeature $rowPackage $packageFeatureMap)) {
                        Add-Finding $findings "ERROR" $tableName $row.Name "Rewards.Item" "Quest reward pool can grant a DLC/feature-scoped item without a matching feature/package gate." $targetFeature "$targetTable.$($ref.RowName)"
                    }
                }
            }
        }

        $rowText = $row | ConvertTo-Json -Depth 30 -Compress
        foreach ($match in [regex]::Matches($rowText, '\/Game\/[^"\\]+(?:\/[^"\\]+)*')) {
            $hint = Find-AssetFeatureHint $match.Value
            if ($hint -and -not (Test-SameOrStrongerGate $rowFeature $hint $rowPackage $packageFeatureMap)) {
                Add-Finding $findings "WARN" $tableName $row.Name "AssetReference" "Row references an asset path that looks feature/DLC-specific but the row is not gated to that feature. Review manually." $hint $match.Value
            }
        }
    }
}

$severityOrder = @{ ERROR = 0; WARN = 1; INFO = 2 }
$sorted = @($findings | Sort-Object @{ Expression = { $severityOrder[$_.Severity] } }, Table, Row, Field)
$summary = [pscustomobject]@{
    GameDataRoot = $GameDataRoot
    ModPath = $ModPath
    CheckedTables = @($modTables.Keys | Sort-Object)
    ErrorCount = @($sorted | Where-Object Severity -eq "ERROR").Count
    WarningCount = @($sorted | Where-Object Severity -eq "WARN").Count
    InfoCount = @($sorted | Where-Object Severity -eq "INFO").Count
    Findings = $sorted
}

if ($ReportPath) {
    $summary | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $ReportPath -NoNewline
}

if ($JsonOnly) {
    $summary | ConvertTo-Json -Depth 12
}
else {
    "DLC safety audit"
    "ModPath: $ModPath"
    "Errors: $($summary.ErrorCount)  Warnings: $($summary.WarningCount)  Info: $($summary.InfoCount)"
    ""
    $sorted | Format-Table Severity, Table, Row, Field, Feature, Reference, Message -AutoSize -Wrap
    if ($ReportPath) {
        ""
        "JSON report: $ReportPath"
    }
}
