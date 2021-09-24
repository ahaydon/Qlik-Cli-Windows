[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "Deprecation warning")]
param()

Describe 'DataConnection' {
    Context 'New-QlikDataConnection' {
        Describe 'when creating a connection' {
            BeforeAll {
                $password = ConvertTo-SecureString -String 'password' -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential("domain\username", $password)
                $Conn = @{
                    name = 'My Connection'
                    type = 'Folder'
                    connectionString = 'C:\tmp'
                    credential = $credential
                }

                $TestRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
                if ($env:TEST_KITCHEN -eq '1') {
                    $TestRoot = Split-Path $TestRoot -Parent
                }
                else {
                    $TestRoot = Join-Path $TestRoot 'helpers'
                }

                Import-Module $TestRoot/connection/connect_helper.psm1 -Force
                GetQlikConnection
            }

            AfterAll {
                $result | Remove-QlikDataConnection
            }

            it 'should set all the provided properties' {
                $script:result = New-QlikDataConnection @Conn

                $result.name | Should -BeExactly $Conn.name
                $result.type | Should -BeExactly $Conn.type
                $result.connectionString | Should -BeExactly $Conn.connectionString
                $result.username | Should -BeExactly $Conn.credential.UserName
            }
        }
    }
}
