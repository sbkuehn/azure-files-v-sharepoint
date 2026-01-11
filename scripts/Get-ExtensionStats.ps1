<#
.SYNOPSIS
Summarize file extensions under a root share.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string] $RootPath,

    [Parameter(Mandatory=$false)]
    [int] $Top = 50,

    [Parameter(Mandatory=$false)]
    [string] $ExportCsvPath,

    [Parameter(Mandatory=$false)]
    [int] $MaxItems = 500000
)

$modulePath = Join-Path $PSScriptRoot "..\src\CloudyMusings.FileDiscovery\CloudyMusings.FileDiscovery.psd1"
Import-Module $modulePath -Force

$logPath = New-DiscoveryLogFile
$results = Get-FileExtensionStats -RootPath $RootPath -Top $Top -MaxItems $MaxItems -LogPath $logPath

$results

if ($ExportCsvPath) {
    $dir = Split-Path $ExportCsvPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
    $results | Export-Csv -Path $ExportCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported to $ExportCsvPath"
    Write-Host "Log: $logPath"
}
