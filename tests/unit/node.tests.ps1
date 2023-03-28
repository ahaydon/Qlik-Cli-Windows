Get-Module Qlik-Cli | Remove-Module -Force
$ProjectRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
Import-Module (Join-Path $ProjectRoot 'Qlik-Cli.psm1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'node.ps1')
. (Join-Path $ProjectRoot 'functions' -AdditionalChildPath 'helper.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'tag.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'customproperty.ps1')

Describe "New-QlikNode" {
    Mock Invoke-QlikPost { $script:node = ConvertFrom-Json $body } -Verifiable
    Mock Invoke-QlikGet { }

    Context 'Service activation' {
        It 'should have all services deactivated by default' {
            New-QlikNode `
                -Hostname 'sense-rim.domain.com'

            $node.configuration.engineEnabled | Should BeNullOrEmpty
            $node.configuration.printingEnabled | Should BeNullOrEmpty
            $node.configuration.proxyEnabled | Should BeNullOrEmpty
            $node.configuration.schedulerEnabled | Should BeNullOrEmpty
            $node.configuration.failoverCandidate | Should BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should have all services activated when switches are set' {
            New-QlikNode `
                -Hostname 'sense-rim.domain.com' `
                -engineEnabled `
                -printingEnabled `
                -proxyEnabled `
                -schedulerEnabled `
                -failoverCandidate

            $node.configuration.engineEnabled | Should Be $true
            $node.configuration.printingEnabled | Should Be $true
            $node.configuration.proxyEnabled | Should Be $true
            $node.configuration.schedulerEnabled | Should Be $true
            $node.configuration.failoverCandidate | Should Be $true

            Assert-VerifiableMock
        }

        It 'should enable all services by default when failoverCandidate is provided' {
            New-QlikNode `
                -Hostname 'sense-rim.domain.com' `
                -failoverCandidate

            $node.configuration.engineEnabled | Should Be $true
            $node.configuration.printingEnabled | Should Be $true
            $node.configuration.proxyEnabled | Should Be $true
            $node.configuration.schedulerEnabled | Should Be $true
            $node.configuration.failoverCandidate | Should Be $true

            Assert-VerifiableMock
        }

        It 'should allow disabling services even if failoverCandidate is provided' {
            New-QlikNode `
                -Hostname 'sense-rim.domain.com' `
                -engineEnabled:$false `
                -printingEnabled:$false `
                -proxyEnabled:$false `
                -schedulerEnabled:$false `
                -failoverCandidate

            $node.configuration.engineEnabled | Should Be $false
            $node.configuration.printingEnabled | Should Be $false
            $node.configuration.proxyEnabled | Should Be $false
            $node.configuration.schedulerEnabled | Should Be $false
            $node.configuration.failoverCandidate | Should Be $true

            Assert-VerifiableMock
        }
    }
}

Describe "Update-QlikNode" {
    Mock Invoke-QlikPut -Verifiable {
        return ConvertFrom-Json $body
    }

    Mock Get-QlikNode -ParameterFilter {
        $id -eq '8eded805-b9d5-49fb-a40f-2f08ee7acbf2'
    } {
        return @{
            id = '8eded805-b9d5-49fb-a40f-2f08ee7acbf2'
            engineEnabled = $true
            printingEnabled = $true
            proxyEnabled = $true
            schedulerEnabled = $true
            failoverCandidate = $true
        }
    }
    Mock Get-QlikNode -ParameterFilter {
        $id -eq 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af'
    } {
        return @{
            id = 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af'
            engineEnabled = $false
            printingEnabled = $false
            proxyEnabled = $false
            schedulerEnabled = $false
            failoverCandidate = $false
            tags = @(@{
                    id = '1b029edc-9c86-4e01-8c39-a10b1d9c4424'
                })
            customProperties = @(@{
                    id = 'a834722d-1306-499e-b028-11454240381b'
                })
        }
    }

    Context 'Service activation' {
        It 'should not change service activation when switches not provided' {
            $node = Update-QlikNode `
                -id '8eded805-b9d5-49fb-a40f-2f08ee7acbf2'

            $node.engineEnabled | Should Be $true
            $node.printingEnabled | Should Be $true
            $node.proxyEnabled | Should Be $true
            $node.schedulerEnabled | Should Be $true
            $node.failoverCandidate | Should Be $true

            Assert-MockCalled Get-QlikNode -ParameterFilter { $id -eq '8eded805-b9d5-49fb-a40f-2f08ee7acbf2' }
        }

        It 'should disable services when switches are set to false' {
            $node = Update-QlikNode `
                -id '8eded805-b9d5-49fb-a40f-2f08ee7acbf2' `
                -engineEnabled:$false `
                -printingEnabled:$false `
                -proxyEnabled:$false `
                -schedulerEnabled:$false `
                -failoverCandidate:$false

            $node.engineEnabled | Should Be $false
            $node.printingEnabled | Should Be $false
            $node.proxyEnabled | Should Be $false
            $node.schedulerEnabled | Should Be $false
            $node.failoverCandidate | Should Be $false

            Assert-MockCalled Get-QlikNode -ParameterFilter { $id -eq '8eded805-b9d5-49fb-a40f-2f08ee7acbf2' }
        }

        It 'should enable services when switches are provided' {
            $node = Update-QlikNode `
                -id 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' `
                -engineEnabled `
                -printingEnabled `
                -proxyEnabled `
                -schedulerEnabled `
                -failoverCandidate

            $node.engineEnabled | Should Be $true
            $node.printingEnabled | Should Be $true
            $node.proxyEnabled | Should Be $true
            $node.schedulerEnabled | Should Be $true
            $node.failoverCandidate | Should Be $true

            Assert-MockCalled Get-QlikNode -ParameterFilter { $id -eq 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' }
        }

        It 'should enable all services by default when failoverCandidate is provided' {
            $node = Update-QlikNode `
                -id 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' `
                -failoverCandidate

            $node.engineEnabled | Should Be $true
            $node.printingEnabled | Should Be $true
            $node.proxyEnabled | Should Be $true
            $node.schedulerEnabled | Should Be $true
            $node.failoverCandidate | Should Be $true

            Assert-MockCalled Get-QlikNode -ParameterFilter { $id -eq 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' }
        }

        It 'should allow disabling services even if failoverCandidate is provided' {
            $node = Update-QlikNode `
                -id 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' `
                -engineEnabled:$false `
                -printingEnabled:$false `
                -proxyEnabled:$false `
                -schedulerEnabled:$false `
                -failoverCandidate

            $node.engineEnabled | Should Be $false
            $node.printingEnabled | Should Be $false
            $node.proxyEnabled | Should Be $false
            $node.schedulerEnabled | Should Be $false
            $node.failoverCandidate | Should Be $true

            Assert-MockCalled Get-QlikNode -ParameterFilter { $id -eq 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' }
        }

        It 'should not enable services by when failoverCandidate is disabled' {
            $node = Update-QlikNode `
                -id 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' `
                -failoverCandidate:$false

            $node.engineEnabled | Should Be $false
            $node.printingEnabled | Should Be $false
            $node.proxyEnabled | Should Be $false
            $node.schedulerEnabled | Should Be $false
            $node.failoverCandidate | Should Be $false

            Assert-MockCalled Get-QlikNode -ParameterFilter { $id -eq 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' }
        }
    }

    Context 'tag' {
        Mock Get-QlikTag {
            return $null
        }

        It 'should be possible to remove all tags' {
            $app = Update-QlikNode `
                -id 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' `
                -tags $null

            $app.tags | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove tags if parameter not provided' {
            $app = Update-QlikNode `
                -id 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af'

            $app.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }

    Context 'custom property' {
        Mock Get-QlikCustomProperty {
            return $null
        }

        It 'should be possible to remove all custom properties' {
            $app = Update-QlikNode `
                -id 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af' `
                -customProperties $null

            $app.customProperties | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove custom properties if parameter not provided' {
            $app = Update-QlikNode `
                -id 'b55e8ac0-dc74-49a9-8ae2-acda027cc8af'

            $app.customProperties | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}
