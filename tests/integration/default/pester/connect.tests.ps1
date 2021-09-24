function CheckConnectResult($result) {
    [version]$result.buildVersion | Should -BeOfType Version
    [datetime]$result.buildDate | Should -BeOfType DateTime
    $result.databaseProvider | Should -BeExactly 'Devart.Data.PostgreSql'
    $result.nodeType | Should -BeExactly 1
    $result.sharedPersistence | Should -BeTrue
    $result.requiresBootstrap | Should -BeOfType Boolean
    $result.singleNodeOnly | Should -BeFalse
    $result.schemaPath | Should -BeExactly 'About'
}

Describe 'Connect-Qlik' {
    Context 'Certificate authentication' {
        Describe 'when connecting' {
            it 'should create a new session' {
                if (Test-Path client.pfx) {
                    $certPath = Resolve-Path client.pfx
                    $password = 'vagrant'
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath, $password, 'DefaultKeySet')
                }
                elseif ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.Platform -eq 'Unix') {
                    Set-ItResult -Skipped -Because "PFX file required when using certificates on non-Windows platforms"
                }
                else {
                    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object Subject -eq 'CN=QlikClient'
                }
                $result = $cert | Connect-Qlik -Computername localhost -Username INTERNAL\sa_api -TrustAllCerts

                CheckConnectResult $result
            }
        }
    }

    Context 'Windows authentication' {
        Describe 'when connecting' {
            it 'should create a new session' {
                if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.Platform -eq 'Unix') {
                    Set-ItResult -Skipped -Because "only valid on Windows platforms"
                }

                $result = Connect-Qlik -Computername localhost -UseDefaultCredentials -TrustAllCerts

                CheckConnectResult $result
            }
        }
    }
}
