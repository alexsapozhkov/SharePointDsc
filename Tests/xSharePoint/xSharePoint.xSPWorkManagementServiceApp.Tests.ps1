[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPWorkManagementServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWorkManagement" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test Work Management App"
            ApplicationPool = "Test App Pool"
        }
        $testParamsComplete = @{
            Name = "Test Work Management App"
            ApplicationPool = "Test App Pool"
            MinimumTimeBetweenEwsSyncSubscriptionSearches =10
            MinimumTimeBetweenProviderRefreshes=10
            MinimumTimeBetweenSearchQueries=10
            NumberOfSubscriptionSyncsPerEwsSyncRun=5
            NumberOfUsersEwsSyncWillProcessAtOnce=5
            NumberOfUsersPerEwsSyncBatch=500
        }

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")

        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Context "When no service applications exist in the current farm" {

            Mock Get-SPServiceApplication { return $null }
            Mock New-SPWorkManagementServiceApplication { }
            Mock Set-SPWorkManagementServiceApplication { }

            Mock New-SPWorkManagementServiceApplicationProxy { }
            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPWorkManagementServiceApplication 
            }
        }

        Context "When service applications exist in the current farm but the specific Work Management app does not" {
            Mock Set-SPWorkManagementServiceApplication { }
            Mock New-SPWorkManagementServiceApplication { }
            Mock New-SPWorkManagementServiceApplicationProxy { }

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
                Assert-MockCalled Set-SPWorkManagementServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

        }

        Context "When a service application exists and is configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Work Management Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
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

        Context "When a service application exists and is not configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Work Management Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                })
            }
            Mock Set-SPWorkManagementServiceApplication { }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParamsComplete | Should Be $false
            }

            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource @testParamsComplete
                Assert-MockCalled Set-SPWorkManagementServiceApplication
                Assert-MockCalled Get-SPWorkManagementServiceApplication
            }
        }
        Context "When a service application exists and Ensure equals 'absent'" {
            $testParamsAbsent = @{
                Name = "Test Work Management App"
            Ensure = "Absent"
            }
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Work Management Service Application"
                    DisplayName = $testParamsAbsent.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                })
            }
            Mock Remove-SPServiceApplication{ }

            It "returns false when the Test method is called" {
                Test-TargetResource $testParamsAbsent | Should Be $false
            }

            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource $testParamsAbsent
                Assert-MockCalled Remove-SPServiceApplication
            }
        }

    }
}
