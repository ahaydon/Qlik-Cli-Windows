function FetchCertificate($storeName, $storeLocation) {
    $certFindValue = "CN=QlikClient"
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $storeName, $storeLocation
    $certs = @()
    try {
        $store.Open("ReadOnly")
        $certs = $store.Certificates.Find("FindBySubjectDistinguishedName", $certFindValue, $false)
    }
    catch {
        Write-Error $_
    }
    finally {
        $store.Close()
    }
    return $certs
}

function GetXrfKey() {
    $alphabet = $Null; For ($a = 97; $a -le 122; $a++) { $alphabet += , [char][byte]$a }
    For ($loop = 1; $loop -le 16; $loop++) {
        $key += ($alphabet | Get-Random)
    }
    return $key
}
