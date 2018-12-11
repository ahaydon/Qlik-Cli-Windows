Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\rule.ps1").Path

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
}
