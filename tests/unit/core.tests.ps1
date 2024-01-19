Get-Module Qlik-Cli | Remove-Module -Force
$ProjectRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
Import-Module (Join-Path $ProjectRoot 'Qlik-Cli.psd1')

Describe 'CallRestUri' {
    InModuleScope Qlik-Cli {
        Describe 'when uploading or downloading files' {
            BeforeAll {
                Mock Invoke-WebRequest -Verifiable {
                    $script:webSessionContainer = @{ Headers = $Headers }
                    return @{
                        UseBasicParsing = $UseBasicParsing
                        TransferEncodingHeader = $Headers.ContainsKey('Transfer-Encoding')
                    }
                }
                Mock Invoke-RestMethod { throw 'Invoke-RestMethod should not be used for file transfers' }
                $script:prefix = 'https://localhost'
                $script:api_params = @{ }
                $script:rawOutput = $true
            }

            BeforeEach {
                $script:webSessionContainer = $null
            }

            It 'should use Invoke-WebRequest' {
                CallRestUri GET /qrs/download/scriptlog @{ OutFile = 'TestDrive:\script.log' }

                Assert-VerifiableMock
            }

            It 'should use basic parsing and transfer-encoding header for uploads' {
                $result = CallRestUri GET /qrs/app/upload @{ InFile = 'TestDrive:\app.qvf' }

                $result.UseBasicParsing | Should -BeTrue
                $result.TransferEncodingHeader | Should -BeTrue
                # Header should be present in request and removed from session after
                $script:webSessionContainer.Headers.Keys | Should -Not -Contain 'Transfer-Encoding'

                Assert-VerifiableMock
            }
        }
    }
}
