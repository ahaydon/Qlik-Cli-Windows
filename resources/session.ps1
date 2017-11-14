function Get-QlikSession {
  [CmdletBinding(DefaultParameterSetName="User")]
  param (
    [parameter(ParameterSetName="Id",Mandatory=$true,Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id,

    [parameter(ParameterSetName="User",Mandatory=$true,Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$userDirectory,

    [parameter(ParameterSetName="User",Mandatory=$true,Position=1,ValueFromPipelinebyPropertyName=$true)]
    [string]$userId,

    [alias("vp")]
    [string]$virtualProxyPrefix,

    [switch]$raw
  )

  PROCESS {
    $proxy = Get-QlikProxy local
    $prefix = "https://$($proxy.serverNodeConfiguration.hostName):$($proxy.settings.restListenPort)/qps"
    if ($virtualProxyPrefix) { $prefix += "/$virtualProxyPrefix" }
    if ($id) {
      $path = "$prefix/session/$id"
    } else {
      $path = "$prefix/user/$userDirectory/$userId"
    }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path
  }
}
