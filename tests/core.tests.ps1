Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psd1").Path

Describe 'CallRestUri' {
    InModuleScope Qlik-Cli {
        Context 'when uploading or downloading files' {
            BeforeAll {
                Mock Invoke-WebRequest -Verifiable {}
                Mock Invoke-RestMethod { throw 'Invoke-RestMethod should not be used for file transfers' }
                $script:prefix = 'https://localhost'
                $script:api_params = @{}
                $script:rawOutput = $true
            }

            it 'should use Invoke-WebRequest' {
                CallRestUri GET /qrs/download/scriptlog @{OutFile='TestDrive:\script.log'}

                Assert-VerifiableMock
            }
        }
    }
}
