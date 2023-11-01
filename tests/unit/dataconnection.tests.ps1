[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "Deprecation warning")]
param()

Get-Module Qlik-Cli | Remove-Module -Force
$ProjectRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
Import-Module (Join-Path $ProjectRoot 'Qlik-Cli.psm1')
. (Join-Path $ProjectRoot 'functions' -AdditionalChildPath 'core.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'dataconnection.ps1')
. (Join-Path $ProjectRoot 'functions' -AdditionalChildPath 'helper.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'tag.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'customproperty.ps1')

Describe "New-QlikDataConnection" {
    Mock Invoke-QlikPost -Verifiable {
        return ConvertFrom-Json $body
    }

    Context 'Password' {
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

        It 'should create a connection with all parameters' {
            $password = ConvertTo-SecureString -String 'password' -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential("username", $password)
            $dc = New-QlikDataConnection `
                -name 'My Connection' `
                -type 'Folder' `
                -connectionString 'C:\Data' `
                -Credential $credential `
                -tags 'testing' `
                -customProperties 'environment=development'

            $dc.name | Should Be 'My Connection'
            $dc.username | Should Be 'username'
            $dc.password | Should Be 'password'
            $dc.connectionString | Should Be 'C:\Data'
            $dc.type | Should Be 'Folder'
            $dc.tags | Should -HaveCount 1
            $dc.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }

    Context 'Username' {
        It 'should include the domain prefix if provided' {
            $password = ConvertTo-SecureString -String 'password' -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential("domain\username", $password)
            $dc = New-QlikDataConnection `
                -name 'My Connection' `
                -type Folder `
                -connectionstring 'C:\Data' `
                -Credential $credential

            $dc.username | Should Be 'domain\username'

            Assert-VerifiableMock
        }
    }

    Context 'tags' {
        Mock Get-QlikTag {
            return @(@{
                    id = 'aa3995e8-9a1c-44b2-8348-71124868e5e1'
                    name = 'Test Tag'
                })
        }

        It 'should assign tags as an array' {
            $dc = New-QlikDataConnection `
                -tags 'Test Tag'

            $dc.tags.GetType().Name | Should Be 'Object[]'
        }

        It 'should be correctly converted to json' {
            Mock Invoke-QlikPost -Verifiable {
                return $body
            }

            $dc = New-QlikDataConnection `
                -tags 'Test Tag'

            $dc | Should Match '"tags":\[\{"id":"aa3995e8-9a1c-44b2-8348-71124868e5e1"}]'
        }
    }
}

Describe "Update-QlikDataConnection" {
    Mock Invoke-QlikPut -Verifiable {
        return ConvertFrom-Json $body
    }

    Mock Invoke-QlikPost {
        return $body
    }

    Mock Get-QlikDataConnection -ParameterFilter {
        $id -eq '158e743b-c59f-490e-900c-b57e66cf8185'
    } {
        return @"
            {
                "id": "158e743b-c59f-490e-900c-b57e66cf8185",
                "username": "username",
                "connectionString": "C:\\Data",
                "tags": [{
                    "id": "1b029edc-9c86-4e01-8c39-a10b1d9c4424"
                }],
                "customProperties": [{
                    "id": "a834722d-1306-499e-b028-11454240381b"
                }]
            }
"@ | ConvertFrom-Json
    }

    Context 'Credential' {
        It 'should be removed when a null value is provided' {
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185' `
                -Credential $null

            $dc.PSObject.Properties.Name | Should -Contain username
            $dc.PSObject.Properties.Name | Should -Contain password
            $dc.username | Should -BeNullOrEmpty
            $dc.password | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should be removed when an empty credential is provided' {
            $password = New-Object System.Security.SecureString
            $credential = [System.Management.Automation.PSCredential]::Empty
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185' `
                -Credential $credential

            $dc.PSObject.Properties.Name | Should -Contain username
            $dc.PSObject.Properties.Name | Should -Contain password
            $dc.username | Should -BeNullOrEmpty
            $dc.password | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }
    }

    Context 'Password' {
        It 'should be updated when a credential is provided' {
            $password = ConvertTo-SecureString -String 'password' -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential("username", $password)
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185' `
                -Credential $credential

            $dc.password | Should Be 'password'

            Assert-VerifiableMock
        }
    }

    Context 'Username' {
        It 'should include the domain prefix if provided' {
            $password = ConvertTo-SecureString -String 'password' -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential("domain\username", $password)
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185' `
                -Credential $credential

            $dc.username | Should Be 'domain\username'

            Assert-VerifiableMock
        }
    }

    Context 'ConnectionString' {
        It 'should be updated when provided' {
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185' `
                -connectionString 'C:\QlikSense'

            $dc.connectionString | Should Be 'C:\QlikSense'

            Assert-VerifiableMock
        }

        It 'should not change when parameter is not specified' {
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185'

            $dc.connectionString | Should Be 'C:\Data'

            Assert-VerifiableMock
        }
    }

    Context 'tags' {
        Mock Get-QlikTag -ParameterFilter { $filter -eq "name eq 'Test Tag'" } {
            return @{
                id = 'aa3995e8-9a1c-44b2-8348-71124868e5e1'
                name = 'Test Tag'
            }
        }
        Mock Get-QlikTag {
            return $null
        }

        It 'should be possible to remove all tags' {
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185' `
                -tags $null

            $dc.tags | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove tags if parameter not provided' {
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185'

            $dc.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }

        It 'should assign tags as an array' {
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185' `
                -tags 'Test Tag'

            $dc.tags.GetType().Name | Should Be 'Object[]'
        }

        It 'should be correctly converted to json' {
            Mock Invoke-QlikPut -Verifiable {
                return $body
            }

            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185' `
                -tags 'Test Tag'

            $dc | Should Match '"tags":\[\{"id":"aa3995e8-9a1c-44b2-8348-71124868e5e1"}]'
        }
    }

    Context 'custom property' {
        Mock Get-QlikCustomProperty {
            return $null
        }

        It 'should be possible to remove all custom properties' {
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185' `
                -customProperties $null

            $dc.customProperties | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove custom properties if parameter not provided' {
            $dc = Update-QlikDataConnection `
                -id '158e743b-c59f-490e-900c-b57e66cf8185'

            $dc.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}
