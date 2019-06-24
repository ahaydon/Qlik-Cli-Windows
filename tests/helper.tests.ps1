Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\app.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\user.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\functions\helper.ps1").Path
. (Resolve-Path "$PSScriptRoot\..\functions\core.ps1").Path

Describe 'GetUser function' {
  Mock Invoke-QlikPut -Verifiable {
    return ConvertFrom-Json $body
  }

  Mock Get-QlikApp -ParameterFilter {
    $id -eq '982a578f-d335-4e4f-81be-c031e6acb780'
  } {
    return @{
      id = '982a578f-d335-4e4f-81be-c031e6acb780'
      tags = @(@{
        id = '1b029edc-9c86-4e01-8c39-a10b1d9c4424'
      })
      customProperties = @(@{
        id = 'a834722d-1306-499e-b028-11454240381b'
      })
    }
  }

  Context 'owner' {
    It 'should assign an owner from ID' {
      $app = Update-QlikApp `
        -id '982a578f-d335-4e4f-81be-c031e6acb780' `
        -owner '4f8fcab4-1de6-41f8-917b-f53342c97e86'

      $app.owner.userDirectory | Should BeNullOrEmpty
      $app.owner.userId | Should BeNullOrEmpty
    }

    It 'should assign an owner from DOMAIN\user' {
      Mock Get-QlikUser -ParameterFilter {
        $filter -eq 'userDirectory eq ''DOMAIN'' and userId eq ''user'''
      } {
        return @{
          id = '4f8fcab4-1de6-41f8-917b-f53342c97e86'
          userDirectory = 'DOMAIN'
          userId = 'user'
        }
      }

      $app = Update-QlikApp `
        -id '982a578f-d335-4e4f-81be-c031e6acb780' `
        -owner 'DOMAIN\user'

      $app.owner.userDirectory | Should Be 'DOMAIN'
      $app.owner.userId | Should Be 'user'
    }

    It 'should assign an owner from email address' {
      Mock Get-QlikUser -ParameterFilter {
        $filter -eq 'userDirectory eq ''domain.com'' and userId eq ''user'''
      } {
        return @{
          id = '4f8fcab4-1de6-41f8-917b-f53342c97e86'
          userDirectory = 'domain.com'
          userId = 'user'
        }
      }

      $app = Update-QlikApp `
        -id '982a578f-d335-4e4f-81be-c031e6acb780' `
        -owner 'user@domain.com'

      $app.owner.userDirectory | Should Be 'domain.com'
      $app.owner.userId | Should Be 'user'
    }

    It 'should assign an owner from InputObject' {
      Mock Get-QlikUser -ParameterFilter {
        $filter -eq 'userDirectory eq ''domain.com'' and userId eq ''user'''
      } {
        return @{
          id = '4f8fcab4-1de6-41f8-917b-f53342c97e86'
          userDirectory = 'domain.com'
          userId = 'user'
        }
      }

      $app = Update-QlikApp `
        -id '982a578f-d335-4e4f-81be-c031e6acb780' `
        -owner @{ id = '4f8fcab4-1de6-41f8-917b-f53342c97e86' }

      $app.owner.id | Should Be '4f8fcab4-1de6-41f8-917b-f53342c97e86'
      $app.owner.userDirectory | Should BeNullOrEmpty
      $app.owner.userId | Should BeNullOrEmpty
    }

    It 'should assign an owner from GetQlikUser' {
      Mock Get-QlikUser -ParameterFilter {
        $id -eq '4f8fcab4-1de6-41f8-917b-f53342c97e86'
      } {
        return [PSCustomObject]@{
          id = '4f8fcab4-1de6-41f8-917b-f53342c97e86'
          userDirectory = 'directory'
          userId = 'user'
        }
      }

      $app = Update-QlikApp `
        -id '982a578f-d335-4e4f-81be-c031e6acb780' `
        -owner (Get-QlikUser '4f8fcab4-1de6-41f8-917b-f53342c97e86')

      $app.owner.id | Should Be '4f8fcab4-1de6-41f8-917b-f53342c97e86'
      $app.owner.userDirectory | Should Be 'directory'
      $app.owner.userId | Should Be 'user'
    }
  }
}
