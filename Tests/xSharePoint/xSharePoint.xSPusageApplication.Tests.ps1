[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPUsageApplication"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPUsageApplication" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Usage Service App"
            UsageLogCutTime = 60
            UsageLogLocation = "L:\UsageLogs"
            UsageLogMaxFileSizeKB = 1024
            UsageLogMaxSpaceGB = 10
            DatabaseName = "SP_Usage"
            DatabaseServer = "sql.test.domain"
            FailoverDatabaseServer = "anothersql.test.domain"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock New-SPUsageApplication { }
        Mock Set-SPUsageService { }
        Mock Get-SPUsageService { return @{
            UsageLogCutTime = $testParams.UsageLogCutTime
            UsageLogDir = $testParams.UsageLogLocation
            UsageLogMaxFileSize = ($testParams.UsageLogMaxFileSizeKB * 1024)
            UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
        }}

        Context "When no service applications exist in the current farm" {

            Mock Get-SPServiceApplication { return $null }

            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPUsageApplication
            }

            It "creates a new service application with custom database credentials" {
                $testParams.Add("DatabaseCredentials", (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
                Set-TargetResource @testParams
                Assert-MockCalled New-SPUsageApplication
            }
        }

        Context "When service applications exist in the current farm but not the specific usage service app" {

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "When a service application exists and is configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Usage and Health Data Collection Service Application"
                    DisplayName = $testParams.Name
                    UsageDatabase = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "When a service application exists and log path are not configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Usage and Health Data Collection Service Application"
                    DisplayName = $testParams.Name
                    UsageDatabase = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            Mock Get-SPUsageService { return @{
                UsageLogCutTime = $testParams.UsageLogCutTime
                UsageLogDir = "C:\Wrong\Location"
                UsageLogMaxFileSize = ($testParams.UsageLogMaxFileSizeKB * 1024)
                UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
            }}

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPUsageService
            }
        }

        Context "When a service application exists and log size is not configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Usage and Health Data Collection Service Application"
                    DisplayName = $testParams.Name
                    UsageDatabase = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            Mock Get-SPUsageService { return @{
                UsageLogCutTime = $testParams.UsageLogCutTime
                UsageLogDir = $testParams.UsageLogLocation
                UsageLogMaxFileSize = ($testParams.UsageLogMaxFileSizeKB * 1024)
                UsageLogMaxSpaceGB = 1
            }}

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPUsageService
            }
        }
    }    
}