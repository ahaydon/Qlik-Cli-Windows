Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\app.ps1").Path

Describe "Publish-QlikApp" {
  Mock Invoke-QlikPut { return $path } -Verifiable

  Context 'name' {
    It 'should be url encoded' {
      $app = Publish-QlikApp `
        -id '982a578f-d335-4e4f-81be-c031e6acb780' `
        -stream 'c75247ad-8dc7-4d1b-9976-702bd4f8fc53' `
        -name 'my test app'

      $app | Should Match 'name=my\+test\+app'

      Assert-VerifiableMock
    }
  }
}

Describe "Copy-QlikApp" {
  Mock Invoke-QlikPost { return $path } -Verifiable

  Context 'name' {
    It 'should be url encoded' {
      $app = Copy-QlikApp `
        -id '982a578f-d335-4e4f-81be-c031e6acb780' `
        -name 'copy of app'

      $app | Should Match 'name=copy\+of\+app'

      Assert-VerifiableMock
    }
  }
}

Describe "Import-QlikApp" {
  Mock Invoke-QlikPost { return $path } -Verifiable

  Context 'name' {
    It 'should be url encoded' {
      $app = Import-QlikApp `
        -file '/some/path/to/app.qvf' `
        -name 'my new app'

      $app | Should Match 'name=my\+new\+app'

      Assert-VerifiableMock
    }
  }
}
