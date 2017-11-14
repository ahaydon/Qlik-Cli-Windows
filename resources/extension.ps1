function Get-QlikExtension {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$Id,
    [string]$Filter,
    [switch]$Full,
    [switch]$raw
  )

  PROCESS {
    $Path = "/qrs/extension"
    If( $Id ) { $Path += "/$Id" }
    If( $Full ) { $Path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet -Path $Path -Filter $Filter
  }
}

function Import-QlikExtension {
  [CmdletBinding()]
  param (
    [String]$ExtensionPath,
    [String]$Password
  )

  PROCESS {
    $Path = "/qrs/extension/upload"
    if($Password) {
      $Password = [System.Web.HttpUtility]::UrlEncode($Password)
      $Path += "?password=$Password"
    }
    return Invoke-QlikUpload $Path $ExtensionPath
  }
}

function Remove-QlikExtension {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$ename
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/extension/name/$ename"
  }
}
