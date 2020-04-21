Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\app.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\functions\helper.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\tag.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\customproperty.ps1").Path

Describe "Publish-QlikApp" {
    Mock Invoke-QlikPut { return $path } -Verifiable

    Context 'name' {
        It 'should be url encoded' {
            $app = Publish-QlikApp `
                -id '982a578f-d335-4e4f-81be-c031e6acb780' `
                -stream 'c75247ad-8dc7-4d1b-9976-702bd4f8fc53' `
                -name 'my test app'

            $app | Should Match 'name=my\+test\+app'

            Assert-VerifiableMock
        }
    }
}

Describe "Copy-QlikApp" {
    Mock Invoke-QlikPost { return $path } -Verifiable

    Context 'name' {
        It 'should be url encoded' {
            $app = Copy-QlikApp `
                -id '982a578f-d335-4e4f-81be-c031e6acb780' `
                -name 'copy of app'

            $app | Should Match 'name=copy\+of\+app'

            Assert-VerifiableMock
        }
    }
}

Describe "Import-QlikApp" {
    Context 'name' {
        It 'should be url encoded' {
            Mock Invoke-QlikPost { return $path } -Verifiable

            $app = Import-QlikApp `
                -file '/some/path/to/app.qvf' `
                -name 'my new app'

            $app | Should Match 'name=my\+new\+app'

            Assert-VerifiableMock
        }
    }

    Context 'filename' {
        It 'should be in double quotes' {
            Mock Invoke-QlikPost { return $body } -Verifiable

            $app = Import-QlikApp `
                -file 'app.qvf' `
                -name 'new app'

            $app | Should Match '"app.qvf"'

            Assert-VerifiableMock
        }
    }
}

Describe "Update-QlikApp" {
    Mock Invoke-QlikPut -Verifiable {
        return ConvertFrom-Json $body
    }

    Mock Get-QlikApp -ParameterFilter {
        $id -eq '982a578f-d335-4e4f-81be-c031e6acb780'
    } {
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

    Mock Get-QlikTag {
        return $null
    }

    Context 'tags' {
        It 'should be possible to remove all tags' {
            $app = Update-QlikApp `
                -id '982a578f-d335-4e4f-81be-c031e6acb780' `
                -tags $null

            $app.tags | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove tags if parameter not provided' {
            $app = Update-QlikApp `
                -id '982a578f-d335-4e4f-81be-c031e6acb780'

            $app.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }

    Context 'custom property' {
        Mock Get-QlikApp {
            return $null
        }

        It 'should be possible to remove all custom properties' {
            $app = Update-QlikApp `
                -id '982a578f-d335-4e4f-81be-c031e6acb780' `
                -customProperties $null

            $app.customProperties | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove custom properties if parameter not provided' {
            $app = Update-QlikApp `
                -id '982a578f-d335-4e4f-81be-c031e6acb780'

            $app.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}
