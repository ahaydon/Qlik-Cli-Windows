Get-Module Qlik-Cli | Remove-Module -Force
$ProjectRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
Import-Module (Join-Path $ProjectRoot 'Qlik-Cli.psm1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'user.ps1')
. (Join-Path $ProjectRoot 'functions' -AdditionalChildPath 'helper.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'tag.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'customproperty.ps1')

Describe "New-QlikUser" {
    Mock Invoke-QlikPost -Verifiable {
        return ConvertFrom-Json $body
    }

    Context 'Create user from parameters' {
        Mock Get-QlikTag {
            return @(@{
                    id = '177cf33f-1ace-41e8-8382-1c443a51352d'
                })
        }
        Mock Get-QlikCustomProperty {
            return @(@{
                    id = 'daa5005e-5f3b-45c5-b2fd-1a1c92c5f367'
                    choiceValues = @('development')
                })
        }

        It 'should create a user with all parameters' {
            $user = New-QlikUser `
                -userId 'me' `
                -userDirectory 'DOMAIN' `
                -name 'It is Me' `
                -tags 'testing' `
                -customProperties 'environment=development'

            $user.name | Should Be 'It is Me'
            $user.userId | Should Be 'me'
            $user.userDirectory | Should Be 'DOMAIN'
            $user.tags | Should -HaveCount 1
            $user.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}

Describe "Update-QlikUser" {
    Mock Invoke-QlikPut -Verifiable {
        return ConvertFrom-Json $body
    }

    Mock Get-QlikUser {
        return @{
            id = '15f4cbf7-a6ec-42c4-82b1-9b7c8ae93a50'
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
            $user = Update-QlikUser `
                -id '15f4cbf7-a6ec-42c4-82b1-9b7c8ae93a50' `
                -tags $null

            $user.tags | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove tags if parameter not provided' {
            $user = Update-QlikUser `
                -id '15f4cbf7-a6ec-42c4-82b1-9b7c8ae93a50'

            $user.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }

    Context 'custom property' {
        Mock Get-QlikCustomProperty {
            return $null
        }

        It 'should be possible to remove all custom properties' {
            $user = Update-QlikUser `
                -id '15f4cbf7-a6ec-42c4-82b1-9b7c8ae93a50' `
                -customProperties $null

            $user.customProperties | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove custom properties if parameter not provided' {
            $user = Update-QlikUser `
                -id '15f4cbf7-a6ec-42c4-82b1-9b7c8ae93a50'

            $user.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}
