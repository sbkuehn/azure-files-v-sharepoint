Set-StrictMode -Version Latest

# region Logging
function New-DiscoveryLogFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $LogDirectory = (Join-Path -Path (Get-Location) -ChildPath "out"),

        [Parameter(Mandatory = $false)]
        [string] $LogName = "discovery.log"
    )

    if (-not (Test-Path -Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }

    $logPath = Join-Path -Path $LogDirectory -ChildPath $LogName
    if (-not (Test-Path -Path $logPath)) {
        New-Item -Path $logPath -ItemType File -Force | Out-Null
    }

    return $logPath
}

function Write-DiscoveryLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO","WARN","ERROR")]
        [string] $Level = "INFO",

        [Parameter(Mandatory = $false)]
        [string] $LogPath
    )

    $timestamp = (Get-Date).ToString("s")
    $line = "{0} [{1}] {2}" -f $timestamp, $Level, $Message

    if ($LogPath) {
        Add-Content -Path $LogPath -Value $line
    } else {
        Write-Verbose $line
    }
}
# endregion Logging

function Get-ShareItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RootPath,

        [Parameter(Mandatory = $false)]
        [string[]] $Include = @("*"),

        [Parameter(Mandatory = $false)]
        [string[]] $Exclude = @(),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 50000000)]
        [int] $MaxItems = 500000,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeDirectories
    )

    if (-not (Test-Path -Path $RootPath)) {
        throw "RootPath not found: $RootPath"
    }

    $common = @{
        Path = $RootPath
        Recurse = $true
        Force = $true
        ErrorAction = "SilentlyContinue"
    }

    if (-not $IncludeDirectories) {
        $common["File"] = $true
    }

    $items = Get-ChildItem @common |
        Where-Object {
            $name = $_.Name
            $includeMatch = $false
            foreach ($pattern in $Include) {
                if ($name -like $pattern) { $includeMatch = $true; break }
            }

            $excludeMatch = $false
            foreach ($pattern in $Exclude) {
                if ($name -like $pattern) { $excludeMatch = $true; break }
            }

            $includeMatch -and (-not $excludeMatch)
        } |
        Select-Object -First $MaxItems

    return $items
}

function Get-LongPaths {
<#
.SYNOPSIS
Finds files and folders with long full paths.

.DESCRIPTION
Long paths often indicate remediation work for SharePoint migrations.
This function scans under RootPath and returns items whose FullName length is greater than MinPathLength.

.PARAMETER RootPath
Root UNC path or local path to scan.

.PARAMETER MinPathLength
Minimum path length to return. 220 is a practical early warning threshold.

.PARAMETER Include
Optional wildcards to include. Defaults to all.

.PARAMETER Exclude
Optional wildcards to exclude.

.PARAMETER MaxItems
Safety limit to cap scanned items.

.PARAMETER IncludeDirectories
If set, includes directories in the scan.

.PARAMETER LogPath
Optional log file path.

.EXAMPLE
Get-LongPaths -RootPath "\\FileServer\Shared" -MinPathLength 220
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RootPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 4000)]
        [int] $MinPathLength = 220,

        [Parameter(Mandatory = $false)]
        [string[]] $Include = @("*"),

        [Parameter(Mandatory = $false)]
        [string[]] $Exclude = @(),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 50000000)]
        [int] $MaxItems = 500000,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeDirectories,

        [Parameter(Mandatory = $false)]
        [string] $LogPath
    )

    Write-DiscoveryLog -Message "Scanning for long paths under $RootPath (MinPathLength=$MinPathLength)" -LogPath $LogPath

    $items = Get-ShareItems -RootPath $RootPath -Include $Include -Exclude $Exclude -MaxItems $MaxItems -IncludeDirectories:$IncludeDirectories

    $results = foreach ($i in $items) {
        $len = $i.FullName.Length
        if ($len -ge $MinPathLength) {
            [pscustomobject]@{
                FullName    = $i.FullName
                Name        = $i.Name
                PathLength  = $len
                IsDirectory = $i.PSIsContainer
                LastWriteTime = $i.LastWriteTime
            }
        }
    }

    $results | Sort-Object PathLength -Descending
}

function Get-FileExtensionStats {
<#
.SYNOPSIS
Summarizes file extensions by count and total size.

.DESCRIPTION
Useful for spotting application-heavy patterns versus user collaboration patterns.

.PARAMETER RootPath
Root path to scan.

.PARAMETER Top
How many extensions to return.

.PARAMETER Include
Optional include wildcards.

.PARAMETER Exclude
Optional exclude wildcards.

.PARAMETER MaxItems
Safety cap for scanned items.

.PARAMETER LogPath
Optional log file path.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RootPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5000)]
        [int] $Top = 50,

        [Parameter(Mandatory = $false)]
        [string[]] $Include = @("*"),

        [Parameter(Mandatory = $false)]
        [string[]] $Exclude = @(),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 50000000)]
        [int] $MaxItems = 500000,

        [Parameter(Mandatory = $false)]
        [string] $LogPath
    )

    Write-DiscoveryLog -Message "Scanning extension stats under $RootPath (Top=$Top)" -LogPath $LogPath

    $items = Get-ShareItems -RootPath $RootPath -Include $Include -Exclude $Exclude -MaxItems $MaxItems

    $grouped = $items | Group-Object Extension

    $results = foreach ($g in $grouped) {
        $totalBytes = 0L
        foreach ($f in $g.Group) { $totalBytes += [int64]$f.Length }

        [pscustomobject]@{
            Extension    = if ([string]::IsNullOrWhiteSpace($g.Name)) { "<none>" } else { $g.Name.ToLowerInvariant() }
            Count        = $g.Count
            TotalBytes   = $totalBytes
            TotalMB      = [math]::Round($totalBytes / 1MB, 2)
        }
    }

    $results |
        Sort-Object Count -Descending |
        Select-Object -First $Top
}

function Get-ColdFiles {
<#
.SYNOPSIS
Finds files that have not been accessed in a given time window.

.DESCRIPTION
Useful for reducing migration scope. Note: LastAccessTime can be unreliable if disabled by policy.

.PARAMETER RootPath
Root path to scan.

.PARAMETER OlderThanYears
Returns files where LastAccessTime is older than now minus this many years.

.PARAMETER Include
Optional include wildcards.

.PARAMETER Exclude
Optional exclude wildcards.

.PARAMETER MaxItems
Safety cap.

.PARAMETER LogPath
Optional log file path.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RootPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 50)]
        [int] $OlderThanYears = 3,

        [Parameter(Mandatory = $false)]
        [string[]] $Include = @("*"),

        [Parameter(Mandatory = $false)]
        [string[]] $Exclude = @(),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 50000000)]
        [int] $MaxItems = 500000,

        [Parameter(Mandatory = $false)]
        [string] $LogPath
    )

    $cutoff = (Get-Date).AddYears(-1 * $OlderThanYears)
    Write-DiscoveryLog -Message "Scanning for cold files under $RootPath (OlderThanYears=$OlderThanYears Cutoff=$cutoff)" -LogPath $LogPath

    $items = Get-ShareItems -RootPath $RootPath -Include $Include -Exclude $Exclude -MaxItems $MaxItems

    $results = foreach ($f in $items) {
        if ($f.LastAccessTime -lt $cutoff) {
            [pscustomobject]@{
                FullName       = $f.FullName
                Name           = $f.Name
                Extension      = $f.Extension
                LengthBytes    = [int64]$f.Length
                LengthMB       = [math]::Round([int64]$f.Length / 1MB, 2)
                LastAccessTime = $f.LastAccessTime
                LastWriteTime  = $f.LastWriteTime
            }
        }
    }

    $results | Sort-Object LastAccessTime
}

function Get-RecentlyModifiedFiles {
<#
.SYNOPSIS
Finds files modified recently.

.DESCRIPTION
A proxy for collaboration candidates. These are files actively changing.

.PARAMETER RootPath
Root path to scan.

.PARAMETER ModifiedWithinDays
Returns files with LastWriteTime within this many days.

.PARAMETER Include
Optional include wildcards.

.PARAMETER Exclude
Optional exclude wildcards.

.PARAMETER MaxItems
Safety cap.

.PARAMETER LogPath
Optional log file path.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RootPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 3650)]
        [int] $ModifiedWithinDays = 30,

        [Parameter(Mandatory = $false)]
        [string[]] $Include = @("*"),

        [Parameter(Mandatory = $false)]
        [string[]] $Exclude = @(),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 50000000)]
        [int] $MaxItems = 500000,

        [Parameter(Mandatory = $false)]
        [string] $LogPath
    )

    $cutoff = (Get-Date).AddDays(-1 * $ModifiedWithinDays)
    Write-DiscoveryLog -Message "Scanning for recently modified files under $RootPath (ModifiedWithinDays=$ModifiedWithinDays Cutoff=$cutoff)" -LogPath $LogPath

    $items = Get-ShareItems -RootPath $RootPath -Include $Include -Exclude $Exclude -MaxItems $MaxItems

    $results = foreach ($f in $items) {
        if ($f.LastWriteTime -ge $cutoff) {
            [pscustomobject]@{
                FullName      = $f.FullName
                Name          = $f.Name
                Extension     = $f.Extension
                LengthBytes   = [int64]$f.Length
                LengthMB      = [math]::Round([int64]$f.Length / 1MB, 2)
                LastWriteTime = $f.LastWriteTime
                LastAccessTime = $f.LastAccessTime
            }
        }
    }

    $results | Sort-Object LastWriteTime -Descending
}

Export-ModuleMember -Function `
    New-DiscoveryLogFile, `
    Write-DiscoveryLog, `
    Get-LongPaths, `
    Get-FileExtensionStats, `
    Get-ColdFiles, `
    Get-RecentlyModifiedFiles
