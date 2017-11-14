function FetchCertificate($storeName, $storeLocation) {
  $certFindValue = "CN=QlikClient"
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $storeName, $storeLocation
  $certs = @()
  try {
    $store.Open("ReadOnly")
    $certs = $store.Certificates.Find("FindBySubjectDistinguishedName", $certFindValue, $false)
  }
  catch {
    Write-Host "Caught an exception:" -ForegroundColor Red
    Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
  }
  finally{
    $store.Close()
  }
  return $certs
}

function GetXrfKey() {
  $alphabet = $Null; For ($a=97;$a -le 122;$a++) { $alphabet += ,[char][byte]$a }
  For ($loop=1; $loop -le 16; $loop++) {
    $key += ($alphabet | Get-Random)
  }
  return $key
}
