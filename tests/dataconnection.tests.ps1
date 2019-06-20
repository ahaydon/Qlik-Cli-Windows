Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\dataconnection.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\functions\helper.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\tag.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\customproperty.ps1").Path

Describe "New-QlikDataConnection" {
  Mock Invoke-QlikPost -Verifiable {
    return ConvertFrom-Json $body
  }

  Context 'Password' {
    Mock Get-QlikTag {
      return @(@{
        id = '177cf33f-1ace-41e8-8382-1c443a51352d'
      })
    }
    Mock Get-QlikCustomProperty {
      return @(@{
        id = 'daa5005e-5f3b-45c5-b2fd-1a1c92c5f367'
      })
    }

    It 'should create a connection with all parameters' {
      $password = ConvertTo-SecureString -String 'password' -AsPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential("username", $password)
      $dc = New-QlikDataConnection `
        -name 'My Connection' `
        -type 'Folder' `
        -connectionString 'C:\Data' `
        -Credential $credential `
        -tags 'testing' `
        -customProperties 'environment=development'

      $dc.name | Should Be 'My Connection'
      $dc.username | Should Be 'username'
      $dc.password | Should Be 'password'
      $dc.connectionString | Should Be 'C:\Data'
      $dc.type | Should Be 'Folder'
      $dc.tags | Should -HaveCount 1
      $dc.customProperties | Should -HaveCount 1

      Assert-VerifiableMock
    }
  }
}

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
      $dc = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185' `
        -tags $null

      $dc.tags | Should -BeNullOrEmpty

      Assert-VerifiableMock
    }

    It 'should not remove tags if parameter not provided' {
      $dc = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185'

      $dc.tags | Should -HaveCount 1

      Assert-VerifiableMock
    }
  }

  Context 'custom property' {
    Mock Get-QlikCustomProperty {
      return $null
    }

    It 'should be possible to remove all custom properties' {
      $dc = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185' `
        -customProperties $null

      $dc.customProperties | Should -BeNullOrEmpty

      Assert-VerifiableMock
    }

    It 'should not remove custom properties if parameter not provided' {
      $dc = Update-QlikDataConnection `
        -id '158e743b-c59f-490e-900c-b57e66cf8185'

      $dc.customProperties | Should -HaveCount 1

      Assert-VerifiableMock
    }
  }
}
