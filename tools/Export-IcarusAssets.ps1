param(
    [Parameter(Mandatory = $true)]
    [string[]]$AssetPath,

    [ValidateSet("Auto", "Raw", "Text", "Texture", "Raw,Text", "Raw,Texture", "Text,Texture", "Raw,Text,Texture")]
    [string]$Format = "Raw,Text",

    [string]$OutputDirectory = "",

    [string]$Ue4ExportExe = "",

    [string]$PakDirectory = "",

    [string]$EngineVersion = "UE4_27",

    [switch]$SkipExisting
)

$ErrorActionPreference = "Stop"

$workspaceRoot = if ($env:ICARUS_MODDING_ROOT) { $env:ICARUS_MODDING_ROOT } else { "C:\Icarus Mod Manager" }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $workspaceRoot "Tools\Ue4Export_Output" }
if (-not $Ue4ExportExe) {
    $Ue4ExportExe = if ($env:UE4EXPORT_EXE) { $env:UE4EXPORT_EXE } else { Join-Path $workspaceRoot "Tools\Ue4Export\Ue4Export.exe" }
}
if (-not $PakDirectory) {
    $PakDirectory = if ($env:ICARUS_PAK_DIR) { $env:ICARUS_PAK_DIR } else { "C:\Program Files (x86)\Steam\steamapps\common\Icarus\Icarus\Content\Paks" }
}

if (-not (Test-Path -LiteralPath $Ue4ExportExe)) {
    throw "Ue4Export.exe not found: $Ue4ExportExe"
}
if (-not (Test-Path -LiteralPath $PakDirectory)) {
    throw "Icarus pak directory not found: $PakDirectory"
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$workDir = Join-Path $OutputDirectory "_assetlists"
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
$assetList = Join-Path $workDir ("assetlist-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

$normalized = foreach ($path in $AssetPath) {
    $p = $path.Trim().Replace("\", "/")
    if (-not $p) { continue }
    if ($p -notmatch "^Icarus/Content/") {
        $p = "Icarus/Content/" + $p.TrimStart("/")
    }
    $p
}

@("[$Format]") + $normalized | Set-Content -LiteralPath $assetList -Encoding ASCII

$args = @("--mix-output")
if ($SkipExisting) { $args += "--skip-existing" }
$args += @($PakDirectory, $EngineVersion, $assetList, $OutputDirectory)

& $Ue4ExportExe @args
$exitCode = $LASTEXITCODE

[pscustomobject]@{
    ExitCode = $exitCode
    AssetList = $assetList
    OutputDirectory = $OutputDirectory
    AssetCount = @($normalized).Count
} | ConvertTo-Json -Depth 4

exit $exitCode
