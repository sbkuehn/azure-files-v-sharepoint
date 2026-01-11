# Example: run a quick discovery pass and export to CSV
$root = "\\FileServer\Shared"

./scripts/Find-LongPaths.ps1 -RootPath $root -MinPathLength 220 -ExportCsvPath .\out\long-paths.csv
./scripts/Get-ExtensionStats.ps1 -RootPath $root -Top 30 -ExportCsvPath .\out\extension-stats.csv
./scripts/Find-ColdFiles.ps1 -RootPath $root -OlderThanYears 3 -ExportCsvPath .\out\cold-files.csv
./scripts/Find-RecentlyModified.ps1 -RootPath $root -ModifiedWithinDays 30 -ExportCsvPath .\out\recently-modified.csv
