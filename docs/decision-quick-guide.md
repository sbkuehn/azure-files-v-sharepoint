# Decision quick guide

## Rule of thumb
If a human collaborates on it, it belongs in SharePoint.
If a system depends on it, it belongs in Azure Files.

## What to measure during discovery
- Long paths and deep nesting
- Extension distribution and total size by extension
- Cold data by last access time
- Recently modified data by last write time
- Top folders by size (add in your own reporting if needed)

## Output files
All wrapper scripts support -ExportCsvPath to create CSV outputs for analysis.
