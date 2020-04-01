Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\content.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\functions\helper.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\tag.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\customproperty.ps1").Path

Describe "New-QlikContentLibrary" {
    Mock Invoke-QlikPost -Verifiable {
        return ConvertFrom-Json $body
    }

    Context 'tag' {
        Mock Get-QlikTag -ParameterFilter {
            $filter -eq 'name eq ''Tag1'''
        } {
            return @{
                id = '0959aa45-92df-4fc7-b0e1-f316db3a2f42'
            }
        }

        Mock Get-QlikTag -ParameterFilter {
            $filter -eq 'name eq ''Tag2'''
        } {
            return @{
                id = '203b324e-c47d-4ffd-8510-68434d7f731e'
            }
        }

        It 'should be possible to assign a tag' {
            $lib = New-QlikContentLibrary `
                -name 'Test Library' `
                -tags 'Tag1'

            $lib.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }

        It 'should be possible to assign multiple tags' {
            $lib = New-QlikContentLibrary `
                -name 'Test Library' `
                -tags 'Tag1', 'Tag2'

            $lib.tags | Should -HaveCount 2

            Assert-VerifiableMock
        }
    }

    Context 'custom property' {
        Mock Get-QlikCustomProperty {
            return @{
                id = '0959aa45-92df-4fc7-b0e1-f316db3a2f42'
            }
        }

        It 'should be possible to assign a custom property value' {
            $lib = New-QlikContentLibrary `
                -name 'Test Library' `
                -customProperties 'Test=Yes'

            $lib.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }

        It 'should be possible to assign multiple custom properties' {
            $lib = New-QlikContentLibrary `
                -name 'Test Library' `
                -customProperties 'Test=Yes', 'Test=it works', 'Multi=Yes'

            $lib.customProperties | Should -HaveCount 3

            Assert-VerifiableMock
        }
    }
}
