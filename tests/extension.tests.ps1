[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "Deprecation warning")]
param()

Get-Module Qlik-Cli | Remove-Module -Force
Import-Module (Resolve-Path "$PSScriptRoot\..\Qlik-Cli.psm1").Path
. (Resolve-Path "$PSScriptRoot\..\resources\extension.ps1").Path

Describe "Import-QlikExtension" {
    Mock Invoke-QlikUpload -Verifiable {
        return $path
    }

    Context 'Password' {
        It 'should be encoded' {
            $password = ConvertTo-SecureString -String 'Pa$$w0rd' -AsPlainText -Force
            $result = Import-QlikExtension `
                -ExtensionPath 'test.qvf' `
                -Password $password

            $result | Should Match 'password=Pa%24%24w0rd'

            Assert-VerifiableMock
        }

        It 'should allow plain text' {
            $password = 'Pa$$w0rd'
            $result = Import-QlikExtension `
                -ExtensionPath 'test.qvf' `
                -Password $password `
                -WarningVariable LastWarning `
                -WarningAction SilentlyContinue

            $result | Should Match 'password=Pa%24%24w0rd'
            $LastWarning | Should Be 'Use of string password is deprecated, please use SecureString instead.'

            Assert-VerifiableMock
        }

        It 'should not warn if no password is provided' {
            $result = Import-QlikExtension `
                -ExtensionPath 'test.qvf' `
                -WarningVariable LastWarning `
                -WarningAction SilentlyContinue

            $LastWarning | Should Be $null

            Assert-VerifiableMock
        }
    }
}
