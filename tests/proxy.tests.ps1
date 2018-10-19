Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\proxy.ps1").Path

Describe "New-QlikVirtualProxy" {
  Mock Invoke-QlikPost { return $body } -Verifiable

  Context 'samlAttributeMap' {
    It 'should have an empty array instead of null' {
      $proxy = New-QlikVirtualProxy `
        -Description 'Test' `
        -sessionCookieHeaderName 'X-Qlik-Session'

      $proxy | Should Match '"samlAttributeMap":\[\]'

      Assert-VerifiableMock
    }

    It 'should have an array even if only one value provided' {
      $proxy = New-QlikVirtualProxy `
        -Description 'Test' `
        -sessionCookieHeaderName 'X-Qlik-Session' `
        -samlAttributeMap @{test='test'}

      $proxy | Should Match '"samlAttributeMap":\[{"test":"test"}\]'

      Assert-VerifiableMock
    }
  }
}
