Get-Module Qlik-Cli | Remove-Module -Force
$ProjectRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
Import-Module (Join-Path $ProjectRoot 'Qlik-Cli.psm1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'rule.ps1')
. (Join-Path $ProjectRoot 'functions' -AdditionalChildPath 'helper.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'tag.ps1')
. (Join-Path $ProjectRoot 'resources' -AdditionalChildPath 'customproperty.ps1')

Describe "New-QlikRule" {
    Mock Invoke-QlikPost -Verifiable {
        return ConvertFrom-Json $body
    }

    Context 'Create rule from parameters' {
        Mock Get-QlikTag {
            return @(@{
                    id = '177cf33f-1ace-41e8-8382-1c443a51352d'
                })
        }

        It 'should create a rule with all parameters' {
            $rule = New-QlikRule `
                -name 'Custom Rule' `
                -category 'Security' `
                -rule '(name = "me")' `
                -resourceFilter 'Stream_*' `
                -actions 1 `
                -ruleContext 'BothQlikSenseAndQMC' `
                -tags 'testing'

            $rule.name | Should Be 'Custom Rule'
            $rule.rule | Should Be '(name = "me")'
            $rule.resourceFilter | Should Be 'Stream_*'
            $rule.actions | Should Be 1
            $rule.category | Should Be 'Security'
            $rule.ruleContext | Should Be 'BothQlikSenseAndQMC'
            $rule.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}

Describe "Update-QlikRule" {
    Mock Invoke-QlikPut -Verifiable {
        return ConvertFrom-Json $body
    }

    Mock Get-QlikRule -ParameterFilter {
        $id -eq 'e46cc4b4-b248-401a-a2fe-b3170532cc00'
    } {
        return @{
            id = 'e46cc4b4-b248-401a-a2fe-b3170532cc00'
            disabled = $false
            tags = @(@{
                    id = '1b029edc-9c86-4e01-8c39-a10b1d9c4424'
                })
        }
    }
    Mock Get-QlikRule -ParameterFilter {
        $id -eq '3ed244ee-a5d7-4211-a16a-7cf54141e5ca'
    } {
        return @{
            id = '3ed244ee-a5d7-4211-a16a-7cf54141e5ca'
            disabled = $true
        }
    }

    Context 'State' {
        It 'should be possible to disable a rule' {
            $rule = Update-QlikRule `
                -id 'e46cc4b4-b248-401a-a2fe-b3170532cc00' `
                -Disabled

            $rule.disabled | Should BeOfType boolean
            $rule.disabled | Should BeTrue

            Assert-VerifiableMock
        }

        It 'should be possible to enable a rule' {
            $rule = Update-QlikRule `
                -id '3ed244ee-a5d7-4211-a16a-7cf54141e5ca' `
                -Disabled:$false

            $rule.disabled | Should BeOfType boolean
            $rule.disabled | Should BeFalse

            Assert-VerifiableMock
        }

        It 'should not disable a rule if disabled switch is not present' {
            $rule = Update-QlikRule `
                -id 'e46cc4b4-b248-401a-a2fe-b3170532cc00'

            $rule.disabled | Should BeOfType boolean
            $rule.disabled | Should BeFalse

            Assert-VerifiableMock
        }
    }

    Context 'tags' {
        Mock Get-QlikTag {
            return $null
        }

        It 'should be possible to remove all tags' {
            $dc = Update-QlikRule `
                -id 'e46cc4b4-b248-401a-a2fe-b3170532cc00' `
                -tags $null

            $dc.tags | Should -BeNullOrEmpty

            Assert-VerifiableMock
        }

        It 'should not remove tags if parameter not provided' {
            $dc = Update-QlikRule `
                -id 'e46cc4b4-b248-401a-a2fe-b3170532cc00'

            $dc.tags | Should -HaveCount 1

            Assert-VerifiableMock
        }
    }
}
