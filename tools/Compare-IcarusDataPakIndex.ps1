param(
    [Parameter(Mandatory = $true)]
    [string]$OldIndexDirectory,

    [Parameter(Mandatory = $true)]
    [string]$NewIndexDirectory,

    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $workspaceRoot "Notes\IcarusDataPakIndex\Comparisons" }

function Import-RequiredCsv {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing index file: $Path" }
    return @(Import-Csv -LiteralPath $Path)
}

function New-KeyedMap {
    param(
        [object[]]$Rows,
        [scriptblock]$KeyScript
    )
    $map = @{}
    foreach ($row in $Rows) {
        $key = & $KeyScript $row
        if ($key) { $map[$key] = $row }
    }
    return $map
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$oldRows = Import-RequiredCsv (Join-Path $OldIndexDirectory "datapak-row-index.csv")
$newRows = Import-RequiredCsv (Join-Path $NewIndexDirectory "datapak-row-index.csv")
$oldItems = Import-RequiredCsv (Join-Path $OldIndexDirectory "datapak-item-connections.csv")
$newItems = Import-RequiredCsv (Join-Path $NewIndexDirectory "datapak-item-connections.csv")

$oldRowMap = New-KeyedMap $oldRows { param($r) "$($r.TableName)|$($r.RowName)" }
$newRowMap = New-KeyedMap $newRows { param($r) "$($r.TableName)|$($r.RowName)" }
$oldItemMap = New-KeyedMap $oldItems { param($r) $r.Item }
$newItemMap = New-KeyedMap $newItems { param($r) $r.Item }

$addedRows = foreach ($key in $newRowMap.Keys) {
    if (-not $oldRowMap.ContainsKey($key)) { $newRowMap[$key] }
}
$removedRows = foreach ($key in $oldRowMap.Keys) {
    if (-not $newRowMap.ContainsKey($key)) { $oldRowMap[$key] }
}

$changedItems = New-Object System.Collections.Generic.List[object]
$interestingColumns = @(
    "Meshable",
    "Itemable",
    "Deployable",
    "Buildable",
    "Interactable",
    "Inventory",
    "InventoryContainer",
    "Consumable",
    "Resource",
    "Ballistic",
    "RequiredFeatureLevel",
    "ManualTags",
    "GeneratedTags"
)

foreach ($item in $newItemMap.Keys) {
    if (-not $oldItemMap.ContainsKey($item)) { continue }
    $old = $oldItemMap[$item]
    $new = $newItemMap[$item]
    foreach ($column in $interestingColumns) {
        if ([string]$old.$column -ne [string]$new.$column) {
            $changedItems.Add([pscustomobject]@{
                Item = $item
                Field = $column
                OldValue = [string]$old.$column
                NewValue = [string]$new.$column
            }) | Out-Null
        }
    }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$addedRowsPath = Join-Path $OutputDirectory "datapak-added-rows-$timestamp.csv"
$removedRowsPath = Join-Path $OutputDirectory "datapak-removed-rows-$timestamp.csv"
$changedItemsPath = Join-Path $OutputDirectory "datapak-changed-item-connections-$timestamp.csv"
$summaryPath = Join-Path $OutputDirectory "datapak-comparison-summary-$timestamp.md"

@($addedRows) | Export-Csv -LiteralPath $addedRowsPath -NoTypeInformation
@($removedRows) | Export-Csv -LiteralPath $removedRowsPath -NoTypeInformation
$changedItems | Export-Csv -LiteralPath $changedItemsPath -NoTypeInformation

$lines = @(
    "# DataPak Index Comparison",
    "",
    "- Old index: ``$OldIndexDirectory``",
    "- New index: ``$NewIndexDirectory``",
    "- Compared: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "",
    "## Counts",
    "",
    "- Added rows: $(@($addedRows).Count)",
    "- Removed rows: $(@($removedRows).Count)",
    "- Changed item connection fields: $($changedItems.Count)",
    "",
    "## Files",
    "",
    "- ``$addedRowsPath``",
    "- ``$removedRowsPath``",
    "- ``$changedItemsPath``"
)
$lines | Set-Content -LiteralPath $summaryPath -Encoding UTF8

[pscustomobject]@{
    AddedRows = @($addedRows).Count
    RemovedRows = @($removedRows).Count
    ChangedItemConnectionFields = $changedItems.Count
    AddedRowsPath = $addedRowsPath
    RemovedRowsPath = $removedRowsPath
    ChangedItemsPath = $changedItemsPath
    SummaryPath = $summaryPath
} | ConvertTo-Json -Depth 4
