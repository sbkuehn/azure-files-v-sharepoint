# Azure File Migration Discovery

A fully ready PowerShell module + scripts to **discover file share patterns** that drive the Azure Files vs SharePoint decision.

This repo is designed to be dropped into GitHub and used as-is during a migration assessment.

## What it does

It helps you answer questions like:

- Where are the **long paths / deep nesting** that will cause pain in SharePoint?
- What file extensions hint at **application-owned** data that likely belongs in Azure Files?
- How much data is **cold** (not accessed in years) and should be archived or excluded?
- Which files have been **modified recently** (good candidates for collaboration workflows)?

Outputs are PowerShell objects and can optionally be exported to CSV.

## Quick start

### Option A: Run scripts directly

```powershell
# 1) Long paths (SharePoint risk)
./scripts/Find-LongPaths.ps1 -RootPath "\\FileServer\\Shared" -MinPathLength 220 -ExportCsvPath .\out\long-paths.csv

# 2) Extension stats (app vs user data hints)
./scripts/Get-ExtensionStats.ps1 -RootPath "\\FileServer\\Shared" -Top 30 -ExportCsvPath .\out\extension-stats.csv

# 3) Cold files (scope reduction)
./scripts/Find-ColdFiles.ps1 -RootPath "\\FileServer\\Shared" -OlderThanYears 3 -ExportCsvPath .\out\cold-files.csv

# 4) Recently modified files (collaboration candidates)
./scripts/Find-RecentlyModified.ps1 -RootPath "\\FileServer\\Shared" -ModifiedWithinDays 30 -ExportCsvPath .\out\recently-modified.csv
```

### Option B: Import the module

```powershell
Import-Module .\src\FileDiscovery\FileDiscovery.psd1 -Force

Get-LongPaths -RootPath "\\FileServer\\Shared" -MinPathLength 220
Get-FileExtensionStats -RootPath "\\FileServer\\Shared" -Top 25
Get-ColdFiles -RootPath "\\FileServer\\Shared" -OlderThanYears 3
Get-RecentlyModifiedFiles -RootPath "\\FileServer\\Shared" -ModifiedWithinDays 30
```

## Notes and limitations

- `LastAccessTime` can be unreliable if access time updates are disabled by policy. The scripts still work, but treat “cold” results as directional.
- Scanning large shares can take time. Use `-MaxItems`, `-Include`, and `-Exclude` parameters to scope.
- Always run discovery from a host with appropriate permissions and stable connectivity to the share.

## Enterprise features included

- Comment-based help
- Parameter validation
- CSV export
- Basic structured logging to a local file
- PSScriptAnalyzer + Pester test scaffolding
- GitHub Actions workflow (Windows) to run lint and tests

## License

MIT. See [LICENSE](LICENSE).
