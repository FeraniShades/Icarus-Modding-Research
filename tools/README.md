# Research Tools

These PowerShell scripts operate on a modder's own local Icarus workspace. They do not include game data or third-party executables.

## Index Builders

- `Build-IcarusDataPakIndex.ps1`: indexes locally extracted Data.pak JSON and row-handle relationships.
- `Build-IcarusJsonClueIndex.ps1`: indexes UAssetGUI/FModel-style JSON exports by useful mechanic clues.
- `Build-IcarusGameplayClueIndex.ps1`: builds gameplay notes from selected ICARUS Wiki pages.

## Search And Comparison

- `Search-IcarusDataPakIndex.ps1`
- `Search-IcarusJsonClueIndex.ps1`
- `Search-IcarusGameplayClueIndex.ps1`
- `Compare-IcarusDataPakIndex.ps1`: compares local index snapshots after game updates.

## Safety And Maintenance

- `Audit-IcarusDlcSafety.ps1`: warns about likely DLC-gating gaps and suspicious acquisition paths.
- `New-IcarusChangelogNote.ps1`: creates a structured weekly update note.
- `Scan-IcarusWorkspace.ps1`: reports which expected local tools and folders are present.
- `Export-IcarusAssets.ps1`: wrapper for a separately installed Ue4Export program.

## Important Notes

- Review script defaults before running. The initial versions assume a conventional `C:\Icarus Mod Manager` workspace but accept path parameters.
- Index outputs may contain substantial derived game data and are intentionally excluded from this repository.
- Wiki and network tools depend on external sites and should identify themselves with a respectful user agent.
- An audit warning is a lead for human review, not proof of a violation.

## Workspace Location

The default workspace is `C:\Icarus Mod Manager`. Override it for all tools in the current PowerShell session with:

```powershell
$env:ICARUS_MODDING_ROOT = "D:\My Icarus Workspace"
```

Individual scripts also accept explicit path parameters.

## Examples

```powershell
& ".\tools\Scan-IcarusWorkspace.ps1"
& ".\tools\Build-IcarusJsonClueIndex.ps1"
& ".\tools\Search-IcarusJsonClueIndex.ps1" -Query "friendly fire"
& ".\tools\Build-IcarusDataPakIndex.ps1" -CreateArchive
& ".\tools\Audit-IcarusDlcSafety.ps1" -ModPath "D:\Mods\Example.EXMOD"
```

Copy `wiki-page-seeds.example.txt` to the gameplay index output folder as `wiki-page-seeds.txt`, then edit the list before running the gameplay builder.
