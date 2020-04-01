Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\proxy.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\functions\helper.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\tag.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\customproperty.ps1").Path

Describe "New-QlikVirtualProxy" {
    Mock Invoke-QlikPost { return $body } -Verifiable

    Context 'samlAttributeMap' {
        It 'should have an empty array instead of null' {
            $proxy = New-QlikVirtualProxy `
                -Description 'Test' `
                -sessionCookieHeaderName 'X-Qlik-Session'

            $proxy | Should Match '"samlAttributeMap":\[\]'

            Assert-VerifiableMock
        }

        It 'should have an array even if only one value provided' {
            $proxy = New-QlikVirtualProxy `
                -Description 'Test' `
                -sessionCookieHeaderName 'X-Qlik-Session' `
                -samlAttributeMap @{test = 'test' }

            $proxy | Should Match '"samlAttributeMap":\[{"test":"test"}\]'

            Assert-VerifiableMock
        }
    }
}

Describe "Update-QlikVirtualProxy" {
    Mock Invoke-QlikPut -Verifiable {
        return ConvertFrom-Json $body
    }

    Mock Get-QlikVirtualProxy {
        return @{
            id = '982a578f-d335-4e4f-81be-c031e6acb780'
            tags = @(@{
                    id = '1b029edc-9c86-4e01-8c39-a10b1d9c4424'
                })
            customProperties = @(@{
                    id = 'a834722d-1306-499e-b028-11454240381b'
                })
        }
    }

    Context 'tags' {
        Mock Get-QlikTag {
            return $null
        }

        It 'should be possible to remove all tags' {
            $vp = Update-QlikVirtualProxy `
                -id '982a578f-d335-4e4f-81be-c031e6acb780' `
                -tags $null

            $vp.tags | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove tags if parameter not provided' {
            $vp = Update-QlikVirtualProxy `
                -id '982a578f-d335-4e4f-81be-c031e6acb780'

            $vp.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }

    Context 'custom property' {
        Mock Get-QlikCustomProperty {
            return $null
        }

        It 'should be possible to remove all custom properties' {
            $vp = Update-QlikVirtualProxy `
                -id '982a578f-d335-4e4f-81be-c031e6acb780' `
                -customProperties $null

            $vp.customProperties | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove custom properties if parameter not provided' {
            $vp = Update-QlikVirtualProxy `
                -id '982a578f-d335-4e4f-81be-c031e6acb780'

            $vp.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}
