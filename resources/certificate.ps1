function Export-QlikCertificate {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string[]]$machineNames,

    [SecureString]$certificatePassword,
    [switch]$includeSecretsKey,
    [ValidateSet("Windows", "Pem")]
    [String]$exportFormat="Windows"
  )

  PROCESS {
    Write-Verbose "Export path: $(Get-QlikCertificateDistributionPath)"
    $body = @{
      machineNames = @( $machineNames );
    }
    If( $certificatePassword ) { $body.certificatePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($CertificatePassword)) }
    If( $includeSecretsKey ) { $body.includeSecretsKey = $true }
    If( $exportFormat ) { $body.exportFormat = $exportFormat }
    $json = $body | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost "/qrs/certificatedistribution/exportcertificates" $json
  }
}
Set-Alias -Name Export-QlikCertificates -Value Export-QlikCertificate

function Get-QlikCertificateDistributionPath {
  [CmdletBinding()]
  param (
  )

  PROCESS {
    $path = "/qrs/certificatedistribution/exportcertificatespath"
    return Invoke-QlikGet -Path $path
  }
}
