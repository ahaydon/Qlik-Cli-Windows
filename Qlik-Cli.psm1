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
  
  $params = $Script:api_params
  If( !$params.Header ) { $params.Header = @{} }
  If( !$params.Header.ContainsKey("x-Qlik-Xrfkey") ) {
    $params.Header.Add("x-Qlik-Xrfkey", $xrfKey)
  }
  
  If( $filter ) { $path += "&filter=$filter" }
  If( $script:webSession -eq $null ) {
    $result = Invoke-RestMethod -Method Get -Uri $path @params -SessionVariable webSession
    $script:webSession = $webSession
  } else {
    $result = Invoke-RestMethod -Method Get -Uri $path @params -WebSession $script:webSession
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
  
  $params = $Script:api_params
  If( !$params.Header.ContainsKey("x-Qlik-Xrfkey") ) {
    $params.Header.Add("x-Qlik-Xrfkey", $xrfKey)
  }

  If( $body ) { Write-Verbose $body }
  $result = Invoke-RestMethod -Method Post -Uri ($Script:prefix + $path) -Body $body @params -ContentType "application/json" -WebSession $script:webSession
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

function DownloadFile($path, $filename) {
  $xrfKey = "abcdefghijklmnop"
  If( $script:webSession -eq $null ) {
    Connect-Qlik > $null
  }
  If( $path.contains("?") ) {
    $path += "&xrfkey=$xrfKey"
  } else {
    $path += "?xrfkey=$xrfKey"
  }
  
  $params = $Script:api_params
  If( !$params.Header.ContainsKey("x-Qlik-Xrfkey") ) {
    $params.Header.Add("x-Qlik-Xrfkey", $xrfKey)
  }

  If( $body ) { Write-Verbose $body }
  $result = Invoke-WebRequest -Method Get -Uri ($Script:prefix + $path) @params -WebSession $script:webSession -OutFile $filename
  return $result
}

function FetchCertificate($storeName, $storeLocation) {
    $certExtension = "1.3.6.1.5.5.7.13.3"
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $storeName, $storeLocation
    $certs = @()
    try {
        $store.Open("ReadOnly")
        $certs = $store.Certificates.Find("FindByExtension", $certExtension, $false)
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
      [switch]$TrustAllCerts,
      [string]$username = "$($env:userdomain)\$($env:username)"
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

    $certs = FetchCertificate "My" "LocalMachine"
    Write-Verbose "Found $($certs.Count) certificates in LocalMachine store"
    If ($certs.Count -eq 0) {
      $certs = FetchCertificate "My" "CurrentUser"
      Write-Verbose "Found $($certs.Count) certificates in CurrentUser store"
    }

    If( $certs.Count -eq 0 ) {
      Write-Verbose "No valid certificate found, using Windows credentials"
      $Script:api_params = @{
        UseDefaultCredentials=$true
      }
    } else {
      Write-Verbose "Using certificate $($certs[0].FriendlyName)"
      
      $Script:api_params = @{
        Certificate=$certs[0]
        Header=@{"X-Qlik-User" = $("UserDirectory={0};UserId={1}" -f $($username -split "\\"))}
      }
      $port = ":4242"
    }
    
    If ( $computername ) {
      If( $computername.ToLower().StartsWith( "http" ) ) {
        $Script:prefix = $computername
      } else {
        $Script:prefix = "https://" + $computername + $port
      }
    } else {
      $Script:prefix = "https://" + $env:computername + $port
    }
    $result = Get-QlikAbout
    return $result
  }
}

function Export-QlikApp {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    [parameter(Position=1)]
    [string]$filename
  )
  
  PROCESS {
    If( [string]::IsNullOrEmpty($filename) ) {
      $file = "$id.qvf"
    }
    $app = (Get-RestUri /qrs/app/$id/export).value
    DownloadFile "/qrs/download/app/$id/$app/temp.qvf" $file
    Write-Verbose "Downloaded $id to $file"
  }
}

function Get-QlikAbout {
  PROCESS {
    return Get-RestUri "/qrs/about"
  }
}

function Get-QlikApp {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )
  
  PROCESS {
    $path = "/qrs/app"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikCustomProperty {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )
  
  PROCESS {
    $path = "/qrs/custompropertydefinition"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
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

function Get-QlikLicense {
  PROCESS {
    return Get-RestUri "/qrs/license"
  }
}

function Get-QlikNode {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$count,
    [switch]$full
  )
  
  PROCESS {
    $path = "/qrs/servernodeconfiguration"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $count -And (-not ($id -And $full)) ) { $path += "/count" }
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
    return Get-RestUri $path $filter
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
    [switch]$count,
    [switch]$full
  )

  PROCESS {
    $path = "/qrs/schedulerservice"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $count -And (-not ($id -And $full)) ) { $path += "/count" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikStream {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )
  
  PROCESS {
    $path = "/qrs/stream"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikTag {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )
  
  PROCESS {
    $path = "/qrs/tag"
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
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/task"
    If( !$raw ) {
      $path += "/table"
      
      $json = (@{
        "entity"="Task"
        "columns"=@(
          @{
            "name"="id"
            "columnType"="Property"
            "definition"="id"
          }
          @{
            "name"="privileges"
            "columnType"="Privileges"
            "definition"="privileges"
          }
          @{
            "name"="compositeEvents"
            "columnType"="Function"
            "definition"="Count(CompositeEvent)"
          }
          @{
            "name"="compositeEventRules"
            "columnType"="Function"
            "definition"="Count(CompositeEvent.Rule)"
          }
          @{
            "name"="userDirectory"
            "columnType"="Property"
            "definition"="userDirectory.name"
          }
          @{
            "name"="resource"
            "columnType"="Property"
            "definition"="app.name"
          }
          @{
            "name"="name"
            "columnType"="Property"
            "definition"="name"
          }
          @{
            "name"="type"
            "columnType"="Property"
            "definition"="taskType"
          }
          @{
            "name"="enabled"
            "columnType"="Property"
            "definition"="enabled"
          }
          @{
            "name"="status"
            "columnType"="Property"
            "definition"="operational.lastExecutionResult.status"
          }
          @{
            "name"="lastExecution"
            "columnType"="Property"
            "definition"="operational.lastExecutionResult.startTime"
          }
          @{
            "name"="nextExecution"
            "columnType"="Property"
            "definition"="operational.nextExecution"
          }
          @{
            "name"="tags"
            "columnType"="List"
            "definition"="tag"
            "list"=@(
              @{
                "name"="name"
                "columnType"="Property"
                "definition"="name"
              }
              @{
                "name"="id"
                "columnType"="Property"
                "definition"="id"
              }
            )
          }
        )
      } | ConvertTo-Json -Compress -Depth 5)
      $table = Post-RestUri $path $json
      $result = @()
      foreach( $row in $table.rows ) {
        $object = @{}
        for ($i = 0; $i -lt $row.Count; $i++){
          $object.Add( $table.columnNames[$i], $row[$i] )
        }
        $result += New-Object -TypeName PSObject -Prop $object
      }
      return $result | select name,status,lastexecution,nextexecution
    } else {
      If( $id ) { $path += "/$id" }
      If( $full ) { $path += "/full" }
      return Get-RestUri $path $filter
    }
  }
}

function Get-QlikUser {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/user"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    $result = Get-RestUri $path $filter
    if( $raw ) {
      return $result
    } else {
      $properties = @('name','userDirectory','userId')
      if( $full ) { $properties += @('roles','inactive','blacklisted','removedExternally') }
      return $result | select -Property $properties
    }
  }
}

function Get-QlikUserDirectory {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full
  )
  
  PROCESS {
    $path = "/qrs/userdirectory"
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

function New-QlikCustomProperty {
  [CmdletBinding()]
  param (
    [string]$name,
    [string]$valueType = "Text",
    [string[]]$choiceValues,

    [ValidateSet("App","ContentLibrary","DataConnection","EngineService","Extension","ProxyService","ReloadTask","RepositoryService","SchedulerService","ServerNodeConfiguration","Stream","User","UserSyncTask","VirtualProxyConfig", IgnoreCase=$false)]
    [string[]]$objectTypes
  )
  
  PROCESS {
    $json = @{
      name = $name;
      valueType = $valueType;
      objectTypes = $objectTypes
    }
    if($ChoiceValues) { $json.Add("ChoiceValues", $ChoiceValues) }
    $json = $json | ConvertTo-Json -Compress -Depth 5
    
    return Post-RestUri "/qrs/custompropertydefinition" $json
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
    [string]$nodePurpose,
    [string[]]$customProperties,
    [string[]]$tags,

    [alias("engine")]
    [switch]$engineEnabled,

    [alias("proxy")]
    [switch]$proxyEnabled,

    [alias("scheduler")]
    [switch]$schedulerEnabled,

    [alias("printing")]
    [switch]$printingEnabled
  )
  
  PROCESS {
    $json = (@{
      configuration=@{
        name=$name;
        hostName=$hostname;
        engineEnabled=$engineEnabled.IsPresent;
        proxyEnabled=$proxyEnabled.IsPresent;
        schedulerEnabled=$schedulerEnabled.IsPresent;
        printingEnabled=$printingEnabled.IsPresent;
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
    [parameter(Mandatory=$true,Position=0)]
    [string]$hostname = $($env:computername),
    [string]$name = $hostname,
    [string]$nodePurpose,
    [string[]]$customProperties,
    [string[]]$tags,

    [alias("engine")]
    [switch]$engineEnabled,

    [alias("proxy")]
    [switch]$proxyEnabled,

    [alias("scheduler")]
    [switch]$schedulerEnabled,

    [alias("printing")]
    [switch]$printingEnabled
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

function Update-QlikCustomProperty {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    [string]$name,
    [string]$valueType = "Text",
    [string[]]$choiceValues,

    [ValidateSet("App","ContentLibrary","DataConnection","EngineService","Extension","ProxyService","ReloadTask","RepositoryService","SchedulerService","ServerNodeConfiguration","Stream","User","UserSyncTask","VirtualProxyConfig", IgnoreCase=$false)]
    [string[]]$objectTypes
  )
  
  PROCESS {
    $prop = Get-QlikCustomProperty $id
    if( $name ) { $prop.name = $name }
    if( $valueType ) { $prop.valueType = $valueType }
    if( $choiceValues ) { $prop.choiceValues = $choiceValues }
    if( $objectTypes ) { $prop.objectTypes = $objectTypes }
    $json = $prop | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/custompropertydefinition/$id" $json
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

function Update-QlikNode {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    
    [string]$name,
    [string]$nodePurpose,
    [string[]]$customProperties,
    [string[]]$tags,
    [switch]$engineEnabled,
    [switch]$proxyEnabled,
    [switch]$schedulerEnabled,
    [switch]$printingEnabled
  )
  
  PROCESS {
    $node = Get-QlikNode $id
    If( $name ) { $node.name = $name }
    If( $nodePurpose ) { $node.nodePurpose = $nodePurpose }
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
      $node.customProperties = $prop
    }
    If( $tags ) { $node.tags = $tags }
    If( $psBoundParameters.ContainsKey("engineEnabled") ) { $node.engineEnabled = $engineEnabled.IsPresent }
    If( $psBoundParameters.ContainsKey("proxyEnabled") ) { $node.proxyEnabled = $proxyEnabled.IsPresent }
    If( $psBoundParameters.ContainsKey("schedulerEnabled") ) { $node.schedulerEnabled = $schedulerEnabled.IsPresent }
    If( $psBoundParameters.ContainsKey("printingEnabled") ) { $node.printingEnabled = $printingEnabled.IsPresent }
    $json = $node | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/servernodeconfiguration/$id" $json
  }
}

function Update-QlikRule {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
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
    switch ($rulecontext)
    {
      both { $context = 0 }
      hub { $context = 1 }
      qmc { $context = 2 }
    }

    $systemrule = Get-QlikRule $id
    If( $name ) { $systemrule.name = $name }
    If( $rule ) { $systemrule.rule = $rule }
    If( $resourceFilter ) { $systemrule.resourceFilter = $resourceFilter }
    If( $category ) { $systemrule.category = $category }
    If( $rulecontext ) { $systemrule.rulecontext = $context }
    If( $actions ) { $systemrule.actions = $actions }
    If( $comment ) { $systemrule.comment = $comment }
    If( $psBoundParameters.ContainsKey("disabled") ) { $systemrule.disabled = $disabled.IsPresent }
    
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

function Update-QlikUser {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    
    [string[]]$roles
  )
  
  PROCESS {
    $user = Get-QlikUser $id -raw
    If( $roles ) { $user.roles = $roles }
    $json = $user | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/user/$id" $json
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

Export-ModuleMember -function Add-Qlik*, Connect-Qlik, Export-Qlik*, Get-Qlik*, New-Qlik*, Register-Qlik*, Set-Qlik*, Start-Qlik*, Update-Qlik*, Get-RestUri
