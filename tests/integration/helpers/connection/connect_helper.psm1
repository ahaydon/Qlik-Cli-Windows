[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSProvideCommentHelp', '')]
param ()

function GetQlikConnection {

    $mod = Get-Module Qlik-Cli
    if ($mod -and $mod.NewBoundScriptBlock( { $null -ne $script:webSessionContainer } ).Invoke()) {
        Write-Verbose 'Already connected'
        return
    }

    if (Test-Path client.pfx) {
        $certPath = Resolve-Path client.pfx
        $password = 'vagrant'
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath, $password, 'DefaultKeySet')
    }
    elseif ($PSVersionTable.PSEdition -ne 'Desktop' -or -not $IsWindows) {
        return
    }
    else {
        $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object Subject -eq 'CN=QlikClient'
    }
    $cert | Connect-Qlik -Computername localhost -Username INTERNAL\sa_api -TrustAllCerts
}

Export-ModuleMember -Function GetQlikConnection
