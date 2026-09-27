param(
    [string]$Root = ""
)

if (-not $Root) {
    $Root = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
}

$paths = [ordered]@{
    Root = $Root
    UAssetFiles = Join-Path $Root "Uasset_Files\Icarus\Content"
    ExtractedMods = Join-Path $Root "Extracted_Mods"
    FModelExports = Join-Path $Root "FModel\Exports"
    FModelOutputExports = Join-Path $Root "FModel\Output\Exports"
    IMB = Join-Path $Root "Icarus_Modding\IMB"
    UAssetGUI = Join-Path $Root "UAssetGUI.exe"
    UnrealPak = Join-Path $Root "UnrealPak"
    UassetInspect = Join-Path $Root "tmp\uasset_inspect"
}

$result = [ordered]@{}
foreach ($key in $paths.Keys) {
    $path = $paths[$key]
    $result[$key] = [ordered]@{
        path = $path
        exists = Test-Path -LiteralPath $path
    }
}

$modRoot = $paths.ExtractedMods
if (Test-Path -LiteralPath $modRoot) {
    $result["RecentExtractedMods"] = Get-ChildItem -LiteralPath $modRoot -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 12 Name, FullName, LastWriteTime
}

$helper = $paths.UassetInspect
if (Test-Path -LiteralPath $helper) {
    $result["UassetInspectFiles"] = Get-ChildItem -LiteralPath $helper -Force |
        Select-Object Name, Length, LastWriteTime
}

$result | ConvertTo-Json -Depth 5
