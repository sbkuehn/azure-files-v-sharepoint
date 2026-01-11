Describe "CloudyMusings.FileDiscovery basic tests" {
    It "Module imports" {
        $modulePath = Join-Path $PSScriptRoot "..\src\CloudyMusings.FileDiscovery\CloudyMusings.FileDiscovery.psd1"
        { Import-Module $modulePath -Force } | Should -Not -Throw
    }

    It "Exports expected functions" {
        $modulePath = Join-Path $PSScriptRoot "..\src\CloudyMusings.FileDiscovery\CloudyMusings.FileDiscovery.psd1"
        Import-Module $modulePath -Force

        (Get-Command Get-LongPaths -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Get-FileExtensionStats -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Get-ColdFiles -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
        (Get-Command Get-RecentlyModifiedFiles -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}
