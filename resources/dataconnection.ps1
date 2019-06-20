function Get-QlikDataConnection {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/dataconnection"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

function New-QlikDataConnection {
  [CmdletBinding()]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "password", Justification="Deprecation warning")]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "", Justification="Deprecation warning")]
  param (
    [parameter(Position=0)]
    [string]$name,
    [parameter(Position=1)]
    [string]$connectionstring,
    [parameter(Position=2)]
    [string]$type,
    [string[]]$customProperties,
    [string[]]$tags,
    [string]$username,
    [string]$password,
    [PSCredential]$Credential
  )

  PROCESS {
    if( $username -Or $password ) {
      Write-Warning "Use of username/password parameters is deprecated, please use Credential instead."
    }
    if( $Credential ) {
      $username = $Credential.GetNetworkCredential().Username
      $password = $Credential.GetNetworkCredential().Password
    }
    $qdc = @{
      customProperties=@();
      engineObjectId=[Guid]::NewGuid();
      username=$username;
      password=$password;
      name=$name;
      connectionstring=$connectionstring;
      type=$type
    }

    if ($PSBoundParameters.ContainsKey("customProperties")) { $qdc.customProperties = @(GetCustomProperties $customProperties) }
    if ($PSBoundParameters.ContainsKey("tags")) { $qdc.tags = @(GetTags $tags) }

    $json = $qdc | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost "/qrs/dataconnection" $json
  }
}

function Remove-QlikDataConnection {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/dataconnection/$id"
  }
}

function Update-QlikDataConnection {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    [string]$ConnectionString,
    [PSCredential]$Credential,
    [string[]]$customProperties,
    [string[]]$tags
  )

  PROCESS {
    $qdc = Get-QlikDataConnection -raw $id
  	If ($PSBoundParameters.ContainsKey("ConnectionString")) {
      $qdc.connectionstring = $ConnectionString
  	}
    if( $Credential ) {
      $qdc.username = $Credential.GetNetworkCredential().Username
      if($qdc.psobject.Properties.name -contains "password") {
	      $qdc.password = $Credential.GetNetworkCredential().Password
      } else {
        $qdc | Add-Member -MemberType NoteProperty -Name "password" -Value $($Credential.GetNetworkCredential().Password)
      }
    }
    if ($PSBoundParameters.ContainsKey("customProperties")) { $qdc.customProperties = @(GetCustomProperties $customProperties) }
    if ($PSBoundParameters.ContainsKey("tags")) { $qdc.tags = @(GetTags $tags) }
    $json = $qdc | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/dataconnection/$id" $json
  }
}
