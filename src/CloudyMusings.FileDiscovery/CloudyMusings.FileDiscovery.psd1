@{
    RootModule = 'CloudyMusings.FileDiscovery.psm1'
    ModuleVersion = '1.0.0'
    GUID = '3f2c7f13-3c6d-4b5c-9f1a-2f9c1f3a2b9c'
    Author = 'Cloudy Musings'
    CompanyName = 'Cloudy Musings'
    Copyright = '(c) 2026'
    Description = 'Discovery scripts for Azure Files vs SharePoint migration decisions.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'New-DiscoveryLogFile',
        'Write-DiscoveryLog',
        'Get-LongPaths',
        'Get-FileExtensionStats',
        'Get-ColdFiles',
        'Get-RecentlyModifiedFiles'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Azure','SharePoint','AzureFiles','Migration','Discovery','CloudyMusings')
            LicenseUri = 'LICENSE'
            ProjectUri = 'README.md'
        }
    }
}
