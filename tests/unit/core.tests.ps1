Get-Module Qlik-Cli | Remove-Module -Force
$ProjectRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
Import-Module (Join-Path $ProjectRoot 'Qlik-Cli.psd1')

Describe 'CallRestUri' {
    InModuleScope Qlik-Cli {
        Describe 'when uploading or downloading files' {
            BeforeAll {
                Mock Invoke-WebRequest -Verifiable { return $UseBasicParsing }
                Mock Invoke-RestMethod { throw 'Invoke-RestMethod should not be used for file transfers' }
                $script:prefix = 'https://localhost'
                $script:api_params = @{ }
                $script:rawOutput = $true
            }

            It 'should use Invoke-WebRequest' {
                CallRestUri GET /qrs/download/scriptlog @{ OutFile = 'TestDrive:\script.log' }

                Assert-VerifiableMock
            }

            It 'should use basic parsing' {
                $result = CallRestUri GET /qrs/app/upload @{ InFile = 'TestDrive:\app.qvf' }

                $result | Should -BeTrue

                Assert-VerifiableMock
            }
        }
    }
}
