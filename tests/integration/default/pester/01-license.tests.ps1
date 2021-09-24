Describe 'Set-QlikLicense' {
    Context 'New license' {
        Describe 'when setting a license' {
            BeforeAll {
                $TestRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent | Split-Path -Parent
                if ($env:TEST_KITCHEN -eq '1') {
                    $TestRoot = Join-Path $TestRoot -ChildPath 'modules'
                }
                $license_path = Join-Path $TestRoot -ChildPath 'data/license.psd1'
                if (!(Test-Path $license_path)) { return }

                $license_file = Get-Item $license_path
                $script:license = Import-LocalizedData -BaseDirectory $license_file.Directory -FileName $license_file.Name
            }

            it 'should save the new license' {
                if (!$license) {
                    Set-ItResult -Skipped -Because "we don't have a license"
                }

                $result = Set-QlikLicense `
                    -serial $license.serial `
                    -control $license.control `
                    -name $license.name `
                    -organization $license.organization `
                    -lef $license.lef

                $result.serial | Should -BeExactly $license.serial
                $result.name | Should -BeExactly $license.name
                $result.organization | Should -BeExactly $license.organization
                $result.lef | Should -BeExactly $license.lef
            }
        }
    }
}
