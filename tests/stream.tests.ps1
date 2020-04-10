Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\stream.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\functions\helper.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\tag.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\customproperty.ps1").Path

Describe "New-QlikStream" {
    Mock Invoke-QlikPost -Verifiable {
        return ConvertFrom-Json $body
    }

    Context 'Create rule from parameters' {
        Mock Get-QlikTag {
            return @(@{
                    id = '177cf33f-1ace-41e8-8382-1c443a51352d'
                })
        }
        Mock Get-QlikCustomProperty {
            return @(@{
                    id = 'daa5005e-5f3b-45c5-b2fd-1a1c92c5f367'
                })
        }

        It 'should create a stream with all parameters' {
            $stream = New-QlikStream `
                -name 'Developers' `
                -tags 'testing' `
                -customProperties 'environment=development'

            $stream.name | Should Be 'Developers'
            $stream.tags | Should -HaveCount 1
            $stream.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}

Describe "Update-QlikStream" {
    Mock Invoke-QlikPut -Verifiable {
        return ConvertFrom-Json $body
    }

    Mock Get-QlikStream {
        return @{
            id = 'e46cc4b4-b248-401a-a2fe-b3170532cc00'
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
            $stream = Update-QlikStream `
                -id 'e46cc4b4-b248-401a-a2fe-b3170532cc00' `
                -tags $null

            $stream.tags | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove tags if parameter not provided' {
            $stream = Update-QlikStream `
                -id 'e46cc4b4-b248-401a-a2fe-b3170532cc00'

            $stream.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }

    Context 'custom property' {
        Mock Get-QlikCustomProperty {
            return $null
        }

        It 'should be possible to remove all custom properties' {
            $stream = Update-QlikStream `
                -id 'e46cc4b4-b248-401a-a2fe-b3170532cc00' `
                -customProperties $null

            $stream.customProperties | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove custom properties if parameter not provided' {
            $stream = Update-QlikStream `
                -id 'e46cc4b4-b248-401a-a2fe-b3170532cc00'

            $stream.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}
