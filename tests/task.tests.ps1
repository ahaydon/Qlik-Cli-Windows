Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\task.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\functions\helper.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\tag.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\customproperty.ps1").Path

Describe "New-QlikTask" {
  Mock Invoke-QlikPost -Verifiable {
    return ConvertFrom-Json $body
  }

  Context 'Create task from parameters' {
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

    It 'should create a stream with all parameters' {
      $task = New-QlikTask `
        -name 'Reload App' `
        -appId '982a578f-d335-4e4f-81be-c031e6acb780' `
        -tags 'testing' `
        -customProperties 'environment=development'

      $task.task.name | Should Be 'Reload App'
      $task.task.tags | Should -HaveCount 1
      $task.task.app.id | Should Be '982a578f-d335-4e4f-81be-c031e6acb780'
      $task.task.customProperties | Should -HaveCount 1

      Assert-VerifiableMock
    }
  }
}

Describe "Update-QlikReloadTask" {
  Mock Invoke-QlikPut -Verifiable {
    return ConvertFrom-Json $body
  }

  Mock Get-QlikReloadTask {
    return @{
      id = '4f9f0e3f-113a-4976-94fa-6b11ab8dc65b'
      tags = @(@{
        id = '1b029edc-9c86-4e01-8c39-a10b1d9c4424'
      })
      customProperties = @(@{
        id = 'a834722d-1306-499e-b028-11454240381b'
      })
    }
  }

  Context 'tags' {
    Mock Get-QlikTag {
      return $null
    }

    It 'should be possible to remove all tags' {
      $task = Update-QlikReloadTask `
        -id '4f9f0e3f-113a-4976-94fa-6b11ab8dc65b' `
        -tags $null

      $task.tags | Should -BeNullOrEmpty

      Assert-VerifiableMock
    }

    It 'should not remove tags if parameter not provided' {
      $task = Update-QlikReloadTask `
        -id '4f9f0e3f-113a-4976-94fa-6b11ab8dc65b'

      $task.tags | Should -HaveCount 1

      Assert-VerifiableMock
    }
  }

  Context 'custom property' {
    Mock Get-QlikCustomProperty {
      return $null
    }

    It 'should be possible to remove all custom properties' {
      $task = Update-QlikReloadTask `
        -id '4f9f0e3f-113a-4976-94fa-6b11ab8dc65b' `
        -customProperties $null

      $task.customProperties | Should -BeNullOrEmpty

      Assert-VerifiableMock
    }

    It 'should not remove custom properties if parameter not provided' {
      $task = Update-QlikReloadTask `
        -id '4f9f0e3f-113a-4976-94fa-6b11ab8dc65b'

      $task.customProperties | Should -HaveCount 1

      Assert-VerifiableMock
    }
  }
}
