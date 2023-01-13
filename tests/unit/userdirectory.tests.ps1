Get-Module Qlik-Cli | Remove-Module -Force
$ProjectRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
Import-Module (Join-Path $ProjectRoot 'Qlik-Cli.psm1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'userdirectory.ps1')
. (Join-Path $ProjectRoot 'functions' -AdditionalChildPath 'helper.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'tag.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'customproperty.ps1')

Describe "New-QlikUserDirectory" {
    Mock Invoke-QlikPost -Verifiable {
        return ConvertFrom-Json $body
    }

    Context 'Create user directory from parameters' {
        Mock Get-QlikTag {
            return @(@{
                    id = '177cf33f-1ace-41e8-8382-1c443a51352d'
                })
        }

        It 'should create a stream with all parameters' {
            $ud = New-QlikUserDirectory `
                -name 'AD' `
                -tags 'testing'

            $ud.name | Should Be 'AD'
            $ud.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}

Describe "Update-QlikUserDirectory" {
    Mock Invoke-QlikPut -Verifiable {
        return ConvertFrom-Json $body
    }

    Mock Get-QlikUserDirectory {
        return @{
            id = '2c317485-1a4a-4112-9bef-e0639262464a'
            tags = @(@{
                    id = '1b029edc-9c86-4e01-8c39-a10b1d9c4424'
                })
        }
    }

    Context 'tags' {
        Mock Get-QlikTag {
            return $null
        }

        It 'should be possible to remove all tags' {
            $user = Update-QlikUserDirectory `
                -id '2c317485-1a4a-4112-9bef-e0639262464a' `
                -tags $null

            $user.tags | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove tags if parameter not provided' {
            $user = Update-QlikUserDirectory `
                -id '2c317485-1a4a-4112-9bef-e0639262464a'

            $user.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}
