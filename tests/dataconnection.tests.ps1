Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\dataconnection.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\functions\helper.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\tag.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\customproperty.ps1").Path

Describe "Update-QlikDataConnection" {
  Mock Invoke-QlikPut -Verifiable {
    return ConvertFrom-Json $body
  }

  Mock Get-QlikDataConnection -ParameterFilter {
    $id -eq '158e743b-c59f-490e-900c-b57e66cf8185'
  } {
    # return '{"id": "158e743b-c59f-490e-900c-b57e66cf8185", "username": "username", "connectionString": "C:\\Data", "tags": {"id": "1b029edc-9c86-4e01-8c39-a10b1d9c4424"}' | ConvertFrom-Json
    return @"
      {
        "id": "158e743b-c59f-490e-900c-b57e66cf8185",
        "username": "username",
        "connectionString": "C:\\Data",
        "tags": [{
          "id": "1b029edc-9c86-4e01-8c39-a10b1d9c4424"
        }],
        "customProperties": [{
          "id": "a834722d-1306-499e-b028-11454240381b"
        }]
      }
"@ | ConvertFrom-Json
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

  Context 'tags' {
    Mock Get-QlikTag {
      return $null
    }

    It 'should be possible to remove all tags' {
      $app = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185' `
        -tags $null

      $app.tags | Should -BeNullOrEmpty

      Assert-VerifiableMock
    }

    It 'should not remove tags if parameter not provided' {
      $app = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185'

      $app.tags | Should -HaveCount 1

      Assert-VerifiableMock
    }
  }

  Context 'custom property' {
    Mock Get-QlikCustomProperty {
      return $null
    }

    It 'should be possible to remove all custom properties' {
      $app = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185' `
        -customProperties $null

      $app.customProperties | Should -BeNullOrEmpty

      Assert-VerifiableMock
    }

    It 'should not remove custom properties if parameter not provided' {
      $app = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185'

      $app.customProperties | Should -HaveCount 1

      Assert-VerifiableMock
    }
  }
}
