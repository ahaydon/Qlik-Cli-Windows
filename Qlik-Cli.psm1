$script:guid = "^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$"

function Get-RestUri($path, $filter) {
  If( $Script:prefix -eq $null ) { Connect-Qlik > $null }
  If( ! $path.StartsWith( "http" ) ) {
    $path = $Script:prefix + $path
  }
  $xrfKey = "abcdefghijklmnop"
  If( $path.contains("?") ) {
    $path += "&xrfkey=$xrfKey"
  } else {
    $path += "?xrfkey=$xrfKey"
  }
  If( $filter ) { $path += "&filter=$filter" }
  If( $script:webSession -eq $null ) {
    $result = Invoke-RestMethod -Method Get -Uri $path -Header @{"x-Qlik-Xrfkey"=$xrfKey} -UseDefaultCredentials -SessionVariable webSession
    $script:webSession = $webSession
  } else {
    $result = Invoke-RestMethod -Method Get -Uri $path -Header @{"x-Qlik-Xrfkey"=$xrfKey} -WebSession $script:webSession
  }
  return $result
}

function Post-RestUri($path, $body) {
  $xrfKey = "abcdefghijklmnop"
  If( $script:webSession -eq $null ) {
    Connect-Qlik > $null
  }
  If( $path.contains("?") ) {
    $path += "&xrfkey=$xrfKey"
  } else {
    $path += "?xrfkey=$xrfKey"
  }
  If( $body ) { Write-Verbose $body }
  $result = Invoke-RestMethod -Method Post -Uri ($Script:prefix + $path) -Body $body -Headers @{"x-Qlik-Xrfkey"=$xrfKey; "Accept"="application/json"} -ContentType "application/json" -WebSession $script:webSession
  return $result
}

function Put-RestUri($path, $body) {
  $xrfKey = "abcdefghijklmnop"
  If( $script:webSession -eq $null ) {
    Connect-Qlik > $null
  }
  If( $path.contains("?") ) {
    $path += "&xrfkey=$xrfKey"
  } else {
    $path += "?xrfkey=$xrfKey"
  }
  Write-Verbose $body
  $result = Invoke-RestMethod -Method Put -Uri ($Script:prefix + $path) -Body $body -Headers @{"x-Qlik-Xrfkey"=$xrfKey; "Accept"="application/json"} -ContentType "application/json" -WebSession $script:webSession
  return $result
}

function Add-QlikProxy {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$ProxyId,
    
    [parameter(Mandatory=$true,Position=1)]
    [string]$VirtualProxyId
  )
  
  PROCESS {
    $proxy = Get-QlikProxy $ProxyId
    $vp = Get-QlikVirtualProxy $VirtualProxyId
    
    $proxy.settings.virtualProxies += $vp
    $json = $proxy | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/proxyservice/$ProxyId" $json
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
    $proxy = Get-QlikVirtualProxy $id
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

function Connect-Qlik {
  [CmdletBinding()]
  param (
      [parameter(Mandatory=$false,Position=0)]
      [string]$computername,
      [switch]$TrustAllCerts
  )

  PROCESS {
    If( $TrustAllCerts ) {
      add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
          public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
          }
        }
"@
      [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }
    If ( $computername ) {
      If( $computername.ToLower().StartsWith( "http" ) ) {
        $Script:prefix = $computername
      } else {
        $Script:prefix = "https://" + $computername
      }
    } else {
      $Script:prefix = "https://" + $env:computername
    }
    $result = Get-QlikAbout
    return $result
  }
}

function Get-QlikAbout {
  PROCESS {
    return Get-RestUri "/qrs/about"
  }
}

function Get-QlikDataConnection {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )
  
  PROCESS {
    $path = "/qrs/dataconnection"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikEngine {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )

  PROCESS {
    $path = "/qrs/engineservice"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikNode {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )
  
  PROCESS {
    $path = "/qrs/servernodeconfiguration"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikProxy {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )

  PROCESS {
    $path = "/qrs/proxyservice"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return = Get-RestUri $path $filter
  }
}

function Get-QlikRelations {
  PROCESS {
    return Get-RestUri "/qrs/about/api/relations"
  }
}

function Get-QlikRule {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )

  PROCESS {
    $path = "/qrs/systemrule"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikScheduler {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )

  PROCESS {
    $path = "/qrs/schedulerservice"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikTask {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )

  PROCESS {
    $path = "/qrs/task"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikVirtualProxy {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )

  PROCESS {
    $path = "/qrs/virtualproxyconfig"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function New-QlikDataConnection {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$name,
    [parameter(Position=1)]
    [string]$connectionstring,
    [parameter(Position=2)]
    [string]$type
  )

  PROCESS {
    $json = (@{
      customProperties=@();
      engineObjectId=[Guid]::NewGuid();
      username="";
      tags=@();
      name=$name;
      connectionstring=$connectionstring;
      type=$type;
    } | ConvertTo-Json -Compress -Depth 5)

    return Post-RestUri "/qrs/dataconnection" $json
  }
}

function New-QlikNode {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$hostname,
    [string]$name = $hostname,
    [switch]$proxy,
    [switch]$engine,
    [switch]$scheduler
  )
  
  PROCESS {
    $json = (@{
      configuration=@{
        name=$name;
        hostName=$hostname;
        engineEnabled=$engine.IsPresent;
        proxyEnabled=$proxy.IsPresent;
        schedulerEnabled=$scheduler.IsPresent;
      }
    } | ConvertTo-Json -Compress -Depth 5)
    $container = Post-RestUri "/qrs/servernodeconfiguration/container" $json
    #Write-Host "http://localhost:4570/certificateSetup"
    return Get-RestUri "/qrs/servernoderegistration/start/$($container.configuration.id)"
  }
}

function New-QlikRule {
  [CmdletBinding()]
  param (
    [string]$name,
    
    [ValidateSet("License","Security","Sync")]
    [string]$category,
    
    [string]$rule,
    
    [alias("filter")]
    [string]$resourceFilter,
    
    [ValidateSet("hub","qmc","both")]
    [alias("context")]
    [string]$rulecontext = "both",
    
    [int]$actions,
    [string]$comment,
    [switch]$disabled
  )
  
  PROCESS {
    # category is case-sensitive so convert to Title Case
    $category = (Get-Culture).TextInfo.ToTitleCase($category.ToLower())
    switch ($rulecontext)
    {
      both { $context = 0 }
      hub { $context = 1 }
      qmc { $context = 2 }
    }
    
    $json = (@{
      category = $category;
      type = "Custom";
      rule = $rule;
      name = $name;
      resourceFilter = $resourceFilter;
      actions = $actions;
      comment = $comment;
      disabled = $disabled.IsPresent;
      ruleContext = $context;
      tags = @();
      schemaPath = "SystemRule"
    } | ConvertTo-Json -Compress)

    return Post-RestUri "/qrs/systemrule" $json
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
    [string[]]$websocketCrossOriginWhiteList = ""
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
    
    $json = (@{
      prefix=$prefix;
      description=$description;
      authenticationModuleRedirectUri=$authenticationModuleRedirectUri;
      loadBalancingServerNodes=$engines;
      sessionCookieHeaderName=$sessionCookieHeaderName;
      websocketCrossOriginWhiteList=$websocketCrossOriginWhiteList;
    } | ConvertTo-Json -Compress -Depth 5)
    
    return Post-RestUri "/qrs/virtualproxyconfig" $json
  }
}

function New-QlikUserAccessGroup {
  [CmdletBinding()]
  param (
    [string]$name
  )
  
  PROCESS {
    $json = (@{
      name=$name
    } | ConvertTo-Json -Compress -Depth 5)
    
    return Post-RestUri "/qrs/License/UserAccessGroup" $json
  }
}

function Register-QlikNode {
  [CmdletBinding()]
  param (
    [string]$hostname = $($env:computername),
    [string]$name = $hostname,
    [switch]$proxy,
    [switch]$engine,
    [switch]$scheduler
  )
  
  PROCESS {
    If( !$psBoundParameters.ContainsKey("hostname") ) { $psBoundParameters.Add( "hostname", $hostname ) }
    If( !$psBoundParameters.ContainsKey("name") ) { $psBoundParameters.Add( "name", $name ) }
    $password = New-QlikNode @psBoundParameters
    $postParams = @{__pwd="$password"}
    Invoke-WebRequest -Uri "http://localhost:4570/certificateSetup" -Method Post -Body $postParams -UseBasicParsing > $null
  }
}

function Set-QlikLicense {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$serial,
    
    [parameter(Mandatory=$true,Position=1)]
    [string]$control,
    
    [parameter(Mandatory=$true,Position=2)]
    [string]$name,

    [parameter(Mandatory=$true,Position=3)]
    [alias("org")]
    [string]$organization,

    [parameter(Mandatory=$false,Position=4)]
    [string]$lef
  )

  PROCESS {
    $resource = "/qrs/license?control=$control"
    $json = @{
      serial = $serial;
      name = $name;
      organization = $organization;
      lef = $lef;
    } | ConvertTo-Json
    Post-RestUri $resource $json

    return $result
  }
}

function Start-QlikTask {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    [switch]$wait
  )
  
  PROCESS {
    $path = "/qrs/task"
    If( $wait ) { $sync = "/synchronous" }
    If( $id -match($script:guid) ) {
      return Post-RestUri "/qrs/task/$id/start$sync"
    } else {
      return Post-RestUri "/qrs/task/start$($sync)?name=$id"
    }
  }
}

function Update-QlikDataConnection {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    
    [string]$ConnectionString
  )
  
  PROCESS {
    $qdc = Get-QlikDataConnection $id
    $qdc.connectionstring = $ConnectionString
    $json = $qdc | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/dataconnection/$id" $json
  }
}

function Update-QlikRule {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    
    [string]$rule
  )
  
  PROCESS {
    $systemrule = Get-QlikRule $id
    If( $rule ) { $systemrule.rule = $rule }
    $json = $systemrule | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/systemrule/$id" $json
  }
}

function Update-QlikScheduler {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    
    [ValidateSet("master","slave","both")]
    [alias("type")]
    [string]$schedulerServiceType
  )
  
  PROCESS {
    $scheduler = Get-QlikScheduler $id
    Write-Verbose $schedulerServiceType
    If( $schedulerServiceType -ne $null ) {
      switch ($schedulerServiceType)
      {
        master { $sched_type = 0 }
        slave { $sched_type = 1 }
        both { $sched_type = 2 }
      }
      $scheduler.settings.schedulerServiceType = $sched_type
    }
    $json = $scheduler | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/schedulerservice/$id" $json
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
    
    [parameter(ValueFromPipeline=$True)]
    [alias("engine")]
    [string[]]$loadBalancingServerNodes,
    
    [alias("wsorigin")]
    [string[]]$websocketCrossOriginWhiteList
  )
  
  PROCESS {
    $proxy = Get-QlikVirtualProxy $id
    If( $prefix ) { $proxy.prefix = $prefix }
    If( $description ) { $proxy.description = $description }
    If( $sessionCookieHeaderName ) { $proxy.sessionCookieHeaderName = $sessionCookieHeaderName }
    If( $psBoundParameters.ContainsKey("authenticationModuleRedirectUri") ) { $proxy.authenticationModuleRedirectUri = $authenticationModuleRedirectUri }
    If( $psBoundParameters.ContainsKey("websocketCrossOriginWhiteList") ) { $proxy.websocketCrossOriginWhiteList = $websocketCrossOriginWhiteList }
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
    $json = $proxy | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/virtualproxyconfig/$id" $json
  }
}