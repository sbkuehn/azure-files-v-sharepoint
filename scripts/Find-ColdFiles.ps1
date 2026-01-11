<#
.SYNOPSIS
Find cold files by LastAccessTime.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string] $RootPath,

    [Parameter(Mandatory=$false)]
    [int] $OlderThanYears = 3,

    [Parameter(Mandatory=$false)]
    [string] $ExportCsvPath,

    [Parameter(Mandatory=$false)]
    [int] $MaxItems = 500000
)

$modulePath = Join-Path $PSScriptRoot "..\filediscovery\filediscovery.psd1"
Import-Module $modulePath -Force

$logPath = New-DiscoveryLogFile
$results = Get-ColdFiles -RootPath $RootPath -OlderThanYears $OlderThanYears -MaxItems $MaxItems -LogPath $logPath

$results

if ($ExportCsvPath) {
    $dir = Split-Path $ExportCsvPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
    $results | Export-Csv -Path $ExportCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported to $ExportCsvPath"
    Write-Host "Log: $logPath"
}
