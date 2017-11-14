function Add-QlikProxy {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$ProxyId,

    [parameter(Mandatory=$true,Position=1)]
    [string]$VirtualProxyId
  )

  PROCESS {
    $proxy = Get-QlikProxy -raw $ProxyId
    $vp = Get-QlikVirtualProxy -raw $VirtualProxyId

    $proxy.settings.virtualProxies += $vp
    $json = $proxy | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/proxyservice/$ProxyId" $json
  }
}

function Add-QlikVirtualProxy {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [alias("engine")]
    [string[]]$loadBalancingServerNodes,
    [alias("wsorigin")]
    [string[]]$websocketCrossOriginWhiteList
  )

  PROCESS {
    $proxy = Get-QlikVirtualProxy -raw $id
    $params = $psBoundParameters
    If( $params.ContainsKey("loadBalancingServerNodes") )
    {
      $params["loadBalancingServerNodes"] = @( $proxy.loadBalancingServerNodes | foreach { $_.id } ) + $loadBalancingServerNodes
    }
    If( $params.ContainsKey("websocketCrossOriginWhiteList") )
    {
      $params["websocketCrossOriginWhiteList"] = $proxy.websocketCrossOriginWhiteList + $websocketCrossOriginWhiteList
    }
    return Update-QlikVirtualProxy @params
  }
}

function Get-QlikProxy {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/proxyservice"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

function Get-QlikVirtualProxy {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/virtualproxyconfig"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

function New-QlikVirtualProxy {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$prefix,

    [parameter(Mandatory=$true,Position=1)]
    [string]$description,

    [parameter(Mandatory=$true,Position=2)]
    [alias("cookie")]
    [string]$sessionCookieHeaderName,

    [alias("authUri")]
    [string]$authenticationModuleRedirectUri,

    [alias("engine")]
    [string[]]$loadBalancingServerNodes = "",

    [alias("wsorigin")]
    [string[]]$websocketCrossOriginWhiteList = "",

    [ValidateSet("ticket","static","dynamic","saml","jwt", IgnoreCase=$false)]
    [String]$authenticationMethod="ticket",

    [String]$samlMetadataIdP="",

    [String]$samlHostUri="",

    [String]$samlEntityId="",

    [String]$samlAttributeUserId="",

    [String]$samlAttributeUserDirectory="",

    [Int]$sessionInactivityTimeout = 30
  )

  PROCESS {
    If( $loadBalancingServerNodes ) {
      $engines = @(
        $loadBalancingServerNodes | foreach {
          If( $_ -match $script:guid ) {
            @{ id = $_ }
          } else {
            $eid = Get-QlikNode -filter "hostname eq '$_'"
            @{ id = $eid.id }
          }
        }
      )
    } else {
      $engines = @()
    }
    $authenticationMethodCode = switch ($authenticationMethod) {
      "ticket"  { 0 }
      "static"  { 1 }
      "dynamic" { 2 }
      "saml"    { 3 }
      "jwt"     { 4 }
    }

    $json = (@{
      prefix=$prefix;
      description=$description;
      authenticationModuleRedirectUri=$authenticationModuleRedirectUri;
      loadBalancingServerNodes=$engines;
      sessionCookieHeaderName=$sessionCookieHeaderName;
      websocketCrossOriginWhiteList=$websocketCrossOriginWhiteList;
      sessionInactivityTimeout=$sessionInactivityTimeout;
      authenticationMethod=$authenticationMethodCode;
      samlMetadataIdP=$samlMetadataIdP;
      samlHostUri=$samlHostUri;
      samlEntityId=$samlEntityId;
      samlAttributeUserId=$samlAttributeUserId;
      samlAttributeUserDirectory=$samlAttributeUserDirectory;
    } | ConvertTo-Json -Compress -Depth 10)

    return Invoke-QlikPost "/qrs/virtualproxyconfig" $json
  }
}

function Remove-QlikVirtualProxy {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/virtualproxyconfig/$id"
  }
}

function Update-QlikProxy {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [ValidateRange(1,65536)]
    [Int]$ListenPort,

    [Bool]$AllowHttp,

    [ValidateRange(1,65536)]
    [Int]$UnencryptedListenPort,

    [ValidateRange(1,65536)]
    [Int]$AuthenticationListenPort,

    [Bool]$KerberosAuthentication,

    [ValidateRange(1,65536)]
    [Int]$UnencryptedAuthenticationListenPort,

    [String]$SslBrowserCertificateThumbprint,

    [ValidateRange(1,300)]
    [Int]$KeepAliveTimeoutSeconds,

    [ValidateRange(512,131072)]
    [Int]$MaxHeaderSizeBytes,

    [ValidateRange(20,1000)]
    [Int]$MaxHeaderLines,

    [ValidateRange(1,65536)]
    [Int]$RestListenPort,

    [String[]]$customProperties,

    [String[]]$virtualProxies
  )

  PROCESS {
    $proxy = Get-QlikProxy -raw -Id $id
    if ($listenPort) { $proxy.settings.listenPort = $listenPort }
    $proxy.settings.allowHttp = $allowHttp
    if ($unencryptedListenPort) { $proxy.settings.unencryptedListenPort = $unencryptedListenPort }
    if ($authenticationListenPort) { $proxy.settings.authenticationListenPort = $authenticationListenPort }
    $proxy.settings.kerberosAuthentication = $kerberosAuthentication
    if ($unencryptedAuthenticationListenPort) { $proxy.settings.unencryptedAuthenticationListenPort = $unencryptedAuthenticationListenPort }
    if ($sslBrowserCertificateThumbprint) { $proxy.settings.sslBrowserCertificateThumbprint = $sslBrowserCertificateThumbprint }
    if ($keepAliveTimeoutSeconds) { $proxy.settings.keepAliveTimeoutSeconds = $keepAliveTimeoutSeconds }
    if ($maxHeaderSizeBytes) { $proxy.settings.maxHeaderSizeBytes = $maxHeaderSizeBytes }
    if ($maxHeaderLines) { $proxy.settings.maxHeaderLines = $maxHeaderLines }
    if ($restListenPort) { $proxy.settings.restListenPort = $restListenPort }
    If( $customProperties ) {
      $prop = @(
        $customProperties | foreach {
          $val = $_ -Split "="
          $p = Get-QlikCustomProperty -filter "name eq '$($val[0])'"
          @{
            value = ($p.choiceValues -eq $val[1])[0]
            definition = $p
          }
        }
      )
      $proxy.customProperties = $prop
    }
    If( $null -ne $virtualProxies ) {
      $set = New-Object System.Collections.Generic.HashSet[string]
      $virtualProxies | foreach {
        If( $_ -match $script:guid ) {
          $res = $set.Add($_)
        } elseif ($_ -ne '') {
          $eid = Get-QlikVirtualProxy -filter "prefix eq '$_'"
          If( $eid )
          {
            $res = $set.Add($eid.id)
          }
        }
      }
      $proxy.settings.virtualProxies | foreach {
        If ($_.defaultVirtualProxy) {
          $res = $set.Add($_.id)
        }
      }
      $vProxies = @(
        $set | foreach {
          @{ id = $_ }
        }
      )
      $proxy.settings.virtualProxies = $vProxies
    }
    $json = $proxy | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/proxyservice/$id" $json
  }
}

function Update-QlikVirtualProxy {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [string]$prefix,
    [string]$description,

    [alias("cookie")]
    [string]$sessionCookieHeaderName,

    [alias("authUri")]
    [string]$authenticationModuleRedirectUri,

    [alias("winAuthPattern")]
    [string]$windowsAuthenticationEnabledDevicePattern,

    [parameter(ValueFromPipeline=$True)]
    [alias("engine")]
    [string[]]$loadBalancingServerNodes,

    [alias("wsorigin")]
    [string[]]$websocketCrossOriginWhiteList,

    [String]$additionalResponseHeaders,

    [Int]$anonymousAccessMode,

    [String]$magicLinkHostUri,

    [String]$magicLinkFriendlyName,

    [ValidateSet("ticket","static","dynamic","saml","jwt", IgnoreCase=$false)]
    [String]$authenticationMethod,

    [String]$samlMetadataIdP,

    [String]$samlHostUri,

    [String]$samlEntityId,

    [String]$samlAttributeUserId,

    [String]$samlAttributeUserDirectory,

    [Int]$sessionInactivityTimeout
  )

  PROCESS {
    $proxy = Get-QlikVirtualProxy -raw $id
    If( $prefix ) { $proxy.prefix = $prefix }
    If( $description ) { $proxy.description = $description }
    If( $sessionCookieHeaderName ) { $proxy.sessionCookieHeaderName = $sessionCookieHeaderName }
    If( $psBoundParameters.ContainsKey("authenticationModuleRedirectUri") ) { $proxy.authenticationModuleRedirectUri = $authenticationModuleRedirectUri }
    If( $psBoundParameters.ContainsKey("websocketCrossOriginWhiteList") ) { $proxy.websocketCrossOriginWhiteList = $websocketCrossOriginWhiteList }
    If( $psBoundParameters.ContainsKey("additionalResponseHeaders") ) { $proxy.additionalResponseHeaders = $additionalResponseHeaders }
    If( $psBoundParameters.ContainsKey("anonymousAccessMode") ) { $proxy.anonymousAccessMode = $anonymousAccessMode }
    If( $psBoundParameters.ContainsKey("windowsAuthenticationEnabledDevicePattern") ) { $proxy.windowsAuthenticationEnabledDevicePattern = $windowsAuthenticationEnabledDevicePattern }
    If( $psBoundParameters.ContainsKey("loadBalancingServerNodes") ) {
      $engines = @(
        $loadBalancingServerNodes | foreach {
          If( $_ -match $script:guid ) {
            @{ id = $_ }
          } else {
            $eid = Get-QlikNode -filter "hostname eq '$_'"
            If( $eid )
            {
              @{ id = $eid.id }
            }
          }
        }
      )
      $proxy.loadBalancingServerNodes = $engines
    }
    If( $psBoundParameters.ContainsKey("magicLinkHostUri") ) { $proxy.magicLinkHostUri = $magicLinkHostUri }
    If( $psBoundParameters.ContainsKey("magicLinkFriendlyName") ) {$proxy.magicLinkFriendlyName = $magicLinkFriendlyName }
    If( $psBoundParameters.ContainsKey("authenticationMethod") ) {
        $proxy.authenticationMethod = switch ($authenticationMethod) {
          "ticket"  { 0 }
          "static"  { 1 }
          "dynamic" { 2 }
          "saml"    { 3 }
          "jwt"     { 4 }
        }
    }
    If( $psBoundParameters.ContainsKey("samlMetadataIdP") ) {$proxy.samlMetadataIdP = $samlMetadataIdP }
    If( $psBoundParameters.ContainsKey("samlHostUri") ) {$proxy.samlHostUri = $samlHostUri }
    If( $psBoundParameters.ContainsKey("samlEntityId") ) {$proxy.samlEntityId = $samlEntityId }
    If( $psBoundParameters.ContainsKey("samlAttributeUserId") ) {$proxy.samlAttributeUserId = $samlAttributeUserId }
    If( $psBoundParameters.ContainsKey("samlAttributeUserDirectory") ) {$proxy.samlAttributeUserDirectory = $samlAttributeUserDirectory }
    If( $psBoundParameters.ContainsKey("sessionInactivityTimeout") ) {$proxy.sessionInactivityTimeout = $sessionInactivityTimeout }
    $json = $proxy | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/virtualproxyconfig/$id" $json
  }
}
