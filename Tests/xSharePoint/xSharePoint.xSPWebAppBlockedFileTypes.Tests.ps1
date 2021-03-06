[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebAppBlockedFileTypes"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWebAppBlockedFileTypes" {
    InModuleScope $ModuleName {
        $testParams = @{
            Url = "http://sites.sharepoint.com"
            Blocked = @("exe", "dll", "ps1")
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock New-SPAuthenticationProvider { }
        Mock New-SPWebApplication { }
        Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $true; AllowAnonymous = $false } }

        Context "The web appliation exists and a specific blocked file type list matches" {
            Mock Get-SPWebApplication { 
                [Collections.Generic.List[String]]$CurrentBlockedFiles = @("exe", "ps1", "dll")
                $webApp = @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    BlockedFileExtensions = $CurrentBlockedFiles
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru 
                return @($webApp)
            }

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The web appliation exists and a specific blocked file type list does not match" {    
            Mock Get-SPWebApplication { 
                [Collections.Generic.List[String]]$CurrentBlockedFiles = @("exe", "pdf", "dll")
                $webApp = @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    BlockedFileExtensions = $CurrentBlockedFiles
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru 
                return @($webApp)
            }

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "updates the workflow settings" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        $testParams = @{
            Url = "http://sites.sharepoint.com"
            EnsureBlocked = @("exe")
            EnsureAllowed = @("pdf")
        }

        Context "The web appliation exists and a list of types to include and exclude both match" {
            Mock Get-SPWebApplication { 
                [Collections.Generic.List[String]]$CurrentBlockedFiles = @("exe", "ps1", "dll")
                $webApp = @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    BlockedFileExtensions = $CurrentBlockedFiles
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru 
                return @($webApp)
            }

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The web appliation exists and a list of types to include and exclude both failed" {    
            Mock Get-SPWebApplication { 
                [Collections.Generic.List[String]]$CurrentBlockedFiles = @("pdf", "dll")
                $webApp = @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    BlockedFileExtensions = $CurrentBlockedFiles
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru 
                return @($webApp)
            }

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateCalled = $false
            It "updates the workflow settings" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateCalled | Should Be $true
            }
        }

        Context "All blocked file type parameters are passed to the methods" {
            Mock Get-SPWebApplication { 
                [Collections.Generic.List[String]]$CurrentBlockedFiles = @("pdf", "dll")
                $webApp = @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    BlockedFileExtensions = $CurrentBlockedFiles
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru 
                return @($webApp)
            }

            $testParams = @{
                Url = "http://sites.sharepoint.com"
                Blocked = @("exe", "dll", "ps1")
                EnsureBlocked = @("exe", "dll")
                EnsureAllowed = @("ps1")
            }

            It "throws an exception on the test method" {
                { Test-TargetResource @testParams } | Should throw
            }

            It "throws an exception on the set method" {
                { Set-TargetResource @testParams } | Should throw
            }
        }

        Context "No blocked file type parameters are passed to the methods" {
            Mock Get-SPWebApplication { 
                [Collections.Generic.List[String]]$CurrentBlockedFiles = @("pdf", "dll")
                $webApp = @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    BlockedFileExtensions = $CurrentBlockedFiles
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:xSPWebApplicationUpdateCalled = $true
                } -PassThru 
                return @($webApp)
            }

            $testParams = @{
                Url = "http://sites.sharepoint.com"
            }

            It "throws an exception on the test method" {
                { Test-TargetResource @testParams } | Should throw
            }

            It "throws an exception on the set method" {
                { Set-TargetResource @testParams } | Should throw
            }
        }
    }    
}