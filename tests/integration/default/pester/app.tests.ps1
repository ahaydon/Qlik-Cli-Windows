Describe 'Import-QlikApp' {
    Context 'Upload' {
        Describe 'when importing an app' {
            BeforeAll {
                $TestRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
                if ($env:TEST_KITCHEN -eq '1') {
                    $TestRoot = Split-Path $TestRoot -Parent
                }
                else {
                    $TestRoot = Join-Path $TestRoot 'helpers'
                }

                Import-Module $TestRoot/connection/connect_helper.psm1 -Force
                GetQlikConnection

                $timer = $null
                do {
                    $app = Get-QlikApp
                    if (! $app) {
                        if ($null -eq $timer) {
                            Write-Warning 'Waiting up to 60 seconds for default apps to be imported'
                            $timer = Get-Date
                        }
                        Start-Sleep -Seconds 5
                    }
                } until ($app -or $timer.AddSeconds(60) -lt (Get-Date))
                $file_path = 'TestDrive:TestApp.qvf'
                $app | Select-Object -First 1 | Export-QlikApp -filename $file_path -SkipData
            }

            AfterEach {
                if ($result) {
                    $result | Remove-QlikApp
                }
            }

            it 'should return the app metadata' {
                if (! (Test-Path $file_path)) {
                    Set-ItResult -Skipped -Because "no apps available to export"
                }

                $script:result = Import-QlikApp -file $file_path -upload

                [guid]$result.id | Should -BeOfType Guid
            }
        }
    }
}
