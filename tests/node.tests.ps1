Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\node.ps1").Path

Describe "New-QlikNode" {
  Mock Invoke-QlikPost { $script:node = ConvertFrom-Json $body } -Verifiable
  Mock Invoke-QlikGet {}

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
  }
}
