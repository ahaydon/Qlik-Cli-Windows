Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\dataconnection.ps1").Path

Describe "Update-QlikDataConnection" {
  Mock Invoke-QlikPut -Verifiable {
    return ConvertFrom-Json $body
  }

  Mock Get-QlikDataConnection -ParameterFilter {
    $id -eq '158e743b-c59f-490e-900c-b57e66cf8185'
  } {
    return '{"id": "158e743b-c59f-490e-900c-b57e66cf8185", "username": "username", "connectionString": "C:\\Data"}' | ConvertFrom-Json
  }

  Context 'Password' {
    It 'should be updated when a credential is provided' {
      $password = ConvertTo-SecureString -String 'password' -AsPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential("username", $password)
      $dc = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185' `
        -Credential $credential

      $dc.password | Should Be 'password'

      Assert-VerifiableMock
    }
  }

  Context 'ConnectionString' {
    It 'should be updated when provided' {
      $dc = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185' `
        -connectionString 'C:\QlikSense'

      $dc.connectionString | Should Be 'C:\QlikSense'

      Assert-VerifiableMock
    }

    It 'should not change when parameter is not specified' {
      $dc = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185'

      $dc.connectionString | Should Be 'C:\Data'

      Assert-VerifiableMock
    }
  }
}
