$script:guid = "^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$"
$script:isDate = "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"

function GetXrfKey() {
  $alphabet = $Null; For ($a=97;$a -le 122;$a++) { $alphabet += ,[char][byte]$a }
  For ($loop=1; $loop -le 16; $loop++) {
    $key += ($alphabet | Get-Random)
  }
  return $key
}

function DeepCopy($data) {
  $ms = New-Object System.IO.MemoryStream
  $bf = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
  $bf.Serialize($ms, $data)
  $ms.Position = 0
  $dataDeep = $bf.Deserialize($ms)
  $ms.Close()
  return $dataDeep
}

function GetCustomProperties($customProperties) {
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
  return $prop
}

function GetTags($tags) {
  $prop = @(
    $tags | foreach {
      $p = Get-QlikTag -filter "name eq '$_'"
      @{
        id = $p.id
      }
    }
  )
  return $prop
}

function CallRestUri($method, $path, $extraParams) {
  If( $Script:prefix -eq $null ) { Connect-Qlik > $null }
  If( ! $path.StartsWith( "http" ) ) {
    $path = $Script:prefix + $path
  }

  $xrfKey = GetXrfKey
  If( $path.contains("?") ) {
    $path += "&xrfkey=$xrfKey"
  } else {
    $path += "?xrfkey=$xrfKey"
  }
  $params = DeepCopy $api_params
  If( $extraParams ) { $params += $extraParams }
  If( !$params.Header ) { $params.Header = @{} }
  If( !$params.Header.ContainsKey("x-Qlik-Xrfkey") ) {
    Write-Verbose "Adding header x-Qlik-Xrfkey: $xrfKey"
    $params.Header.Add("x-Qlik-Xrfkey", $xrfKey)
  }
  If( $params.Body ) { Write-Verbose $params.Body }

  
  Write-Verbose "Calling $method for $path"
  If( $script:webSession -eq $null ) {
    $result = Invoke-RestMethod -Method $method -Uri $path @params -SessionVariable webSession
    $script:webSession = $webSession
  } else {
    $result = Invoke-RestMethod -Method $method -Uri $path @params -WebSession $script:webSession
  }

  return $result
}





function Get-RestUri($path, $filter) {
  If( $filter ) {
    If( $path.contains("?") ) {
      $path += "&filter=$filter"
    } else {
      $path += "?filter=$filter"
    }
  }

  
  return CallRestUri Get $path
}

function Post-RestUri($path, $body) {
  $params = @{
    ContentType = "application/json"
    Body = $body
  }

  return CallRestUri Post $path $params
}

function Put-RestUri($path, $body) {
  $params = @{
    ContentType = "application/json"
    Body = $body
  }

  
  return CallRestUri Put $path $params
}

function Delete-RestUri($path) {
  return CallRestUri Delete $path
}

function DownloadFile($path, $filename) {
  $params = @{
    OutFile = $filename
  }

  return CallRestUri Get $path $params
}

function UploadFile($path, $filename) {
  $params = @{
    InFile = $filename
    ContentType = "application/vnd.qlik.sense.app"
  }

  return CallRestUri Post $path $params
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

function FormatOutput($objects, $schemaPath) {
  Write-Debug "Resolving enums"
  If( !$Script:enums ) {
    # If enums haven't been read get them and save them for later use
    $enums = Get-RestUri "/qrs/about/api/enums"
    $Script:enums = $enums | Get-Member -MemberType NoteProperty | foreach { $enums.$($_.Name) }
  }
  If( !$Script:relations ) {
    # If relations haven't been read get them and save them for later use
    $Script:relations = Get-QlikRelations
  }
  foreach( $object in $objects ) {
    # Determine the object type being formatted
    If( !$schemaPath ) { $schemaPath = $object.schemaPath }
    Write-Debug "Schema path: $schemaPath"
    foreach( $prop in ( $object | Get-Member -MemberType NoteProperty ) ) {
      If( $object.$($prop.Name) -is [string] -And $object.$($prop.Name) -match $isDate ) {
        # Update any value that looks like a date to a more human readable format
        $object.$($prop.Name) = Get-Date -Format "yyyy/MM/dd HH:mm" $object.$($prop.Name)
      }
      Write-Debug "Property: $schemaPath.$($prop.Name)"
      # Find enums related to the current object property
      $enumsRelated = $Script:enums | where-object { $_.Usages -contains "$schemaPath.$($prop.Name)" }
      If( $enumsRelated ) {
        # If there is an enum for the property then resolve it
        $value = ((($enumsRelated | select -expandproperty values | where {$_ -like "$($object.$($prop.Name)):*" }) -split ":")[1]).TrimStart()
        Write-Debug "Resolving $($prop.Name) from $($object.$($prop.Name)) to $value"
        $object.$($prop.Name) = $value
      }
      # Check for relations referenced by the property
      $relatedRelations = $Script:relations -like "$schemaPath.$($prop.Name) > *"
      If( $relatedRelations ) {
        # If there are relations for the property then call self for the object
        Write-Debug "Traversing $($prop.Name)"
        $object.$($prop.Name) = FormatOutput $object.$($prop.Name) $(($relatedRelations -Split ">")[1].TrimStart())
      }
    }
  }
  return $objects
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
<#
.SYNOPSIS
  Establishes a session with a Qlik Sense server, other Qlik cmdlets will use this session to invoke commands.
.LINK
  https://github.com/ahaydon/Qlik-Cli
#>
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$false,Position=0)]
    # Name of the Sense server to connect to
    [string]$computername,
    # Disable checking of certificate trust
    [switch]$TrustAllCerts,
    # UserId to use with certificate authentication in the format domain\username
    [string]$username = "$($env:userdomain)\$($env:username)",
    [parameter(ValueFromPipeline=$true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate]$certificate
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
    If( !$certificate ) {
      $certs = @(FetchCertificate "My" "LocalMachine")
      Write-Verbose "Found $($certs.Count) certificates in LocalMachine store"
      If( $certs.Count -eq 0 ) {
        $certs = @(FetchCertificate "My" "CurrentUser")
        Write-Verbose "Found $($certs.Count) certificates in CurrentUser store"
      }
      If( $certs.Count -gt 0 ) {
        $certificate = $certs[0]
      }
    }

    If( !$certificate ) {
      Write-Verbose "No valid certificate found, using Windows credentials"
      $Script:api_params = @{
        UseDefaultCredentials=$true
      }
    } else {
      Write-Verbose "Using certificate $($certificate.FriendlyName)"

      $Script:api_params = @{
        Certificate=$certificate
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
    $Script:webSession = $null
    $result = Get-QlikAbout
    return $result
  }
}

function Copy-QlikApp {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    [parameter(ValueFromPipelinebyPropertyName=$True,Position=1)]
    [string]$name
  )

  PROCESS {
    $path = "/qrs/app/$id/copy"
    If( $name ) {
      $path += "?name=$name"
    }

    return Post-RestUri $path
  }
}

function Export-QlikApp {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    [parameter(ValueFromPipelinebyPropertyName=$True,Position=1)]
    [string]$filename
  )

  PROCESS {
    Write-Verbose filename=$filename
    If( [string]::IsNullOrEmpty($filename) ) {
      $file = "$id.qvf"
    } else {
      $file = $filename
    }
    Write-Verbose file=$file
    $app = (Get-RestUri /qrs/app/$id/export).value
    DownloadFile "/qrs/download/app/$id/$app/temp.qvf" $file
    Write-Verbose "Downloaded $id to $file"
  }
}

function Export-QlikAppList {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$sorting,
    [string]$path
  )
  PROCESS {
    If( !$path ) { $path = "Exported apps" }
    If( !(Test-Path $path) ){
      md $path
    }
    If( $sorting ) {
      $appList = Get-QlikApp -sorting $sorting 
    } else {
      $appList = Get-QlikApp
    }
    
    $appListSize = $appList.count

    Write-Verbose "Start AppList export..."
    Write-Verbose "Num. of apps: $appListSize"

    $count = 1
    foreach($app in $appList) {
      Write-Verbose "Downloading app $count of $appListSize..."
      Export-QlikApp $app.id "$path\$($app.name).qvf"
      $count++
    }
    Write-Verbose "Export finished!"
  }
}

function Export-QlikCertificates {
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
    Write-Verbose "Export path: $(Get-QlikCertificateDistributionPath -Params $params)"
    $body = @{
      machineNames = @( $machineNames );
    }
    If( $certificatePassword ) { $body.certificatePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($CertificatePassword)) }
    If( $includeSecretsKey ) { $body.includeSecretsKey = $true }
    If( $exportFormat ) { $body.exportFormat = $exportFormat }
    $json = $body | ConvertTo-Json -Compress -Depth 5

    return Post-RestUri "/qrs/certificatedistribution/exportcertificates" $json
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
    [switch]$full,
    [switch]$raw,
	[string]$sorting
  )

  PROCESS {
    $path = "/qrs/app"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
	If( $sorting ) { $path += "?orderBy= $sorting" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikAccessTypeInfo {
  PROCESS {
    return Get-RestUri "/qrs/license/accesstypeinfo"
  }
}

function Get-QlikCertificateDistributionPath {
  [CmdletBinding()]
  param (
    [HashTable]$params
  )

  PROCESS {
    $path = "/qrs/certificatedistribution/exportcertificatespath"
    return Get-RestUri -Path $path -Params $params
  }
}

function Get-QlikContentLibrary {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/contentlibrary"
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
    [switch]$full,
    [switch]$raw
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
    [switch]$full,
    [switch]$raw
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
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/engineservice"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikExtension {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$Id,
    [string]$Filter,
    [switch]$Full
  )

  PROCESS {
    $Path = "/qrs/extension"
    If( $Id ) { $Path += "/$Id" }
    If( $Full ) { $Path += "/full" }
    return Get-RestUri -Path $Path -Filter $Filter
  }
}

function Get-QlikLicense {
  PROCESS {
    return Get-RestUri "/qrs/license"
  }
}

function Get-QlikLoginAccess {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/license/loginAccessType"
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
    [switch]$count,
    [switch]$full,
    [switch]$raw
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
    [switch]$full,
    [switch]$raw
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
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/systemrule"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    $result = Get-RestUri $path $filter
    If( !$raw ) { $result = FormatOutput $result }
    return $result
  }
}

function Get-QlikReloadTask {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$Id,
    [string]$Filter,
    [switch]$Full
  )

  PROCESS {
    $path = "/qrs/reloadtask"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri -Path $path -Filter $filter
  }
}

function Get-QlikScheduler {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$count,
    [switch]$full,
    [switch]$raw
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
    [switch]$full,
    [switch]$raw
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
    [switch]$full,
    [switch]$raw
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
      If( $id ) { $path += "/$id" }
      $path += "/full"
      $result = Get-RestUri $path $filter
      $result = FormatOutput $result
      If( !$full ) {
        $result = $result | foreach {
          $props = @{
            name = $_.name
            status = $_ | select -ExpandProperty operational | select -ExpandProperty lastExecutionResult | select -ExpandProperty status
            lastExecution = $_ | select -ExpandProperty operational | select -ExpandProperty lastExecutionResult | select -ExpandProperty startTime
            nextExecution = $_ | select -ExpandProperty operational | select -ExpandProperty nextExecution
          }
          New-Object -TypeName PSObject -Prop $props
        }
      }
      return $result
    } else {
      If( $id ) { $path += "/$id" }
      If( $full ) { $path += "/full" }
      $result = Get-RestUri $path $filter
      return $result
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
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/userdirectory"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    return Get-RestUri $path $filter
  }
}

function Get-QlikValidEngines {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$proxyId,
    [parameter(Position=1)]
    [string]$proxyPrefix,
    [parameter(Position=2)]
    [string]$appId,
    [parameter(Position=3)]
    [ValidateSet("Production","Development","Any")]
    [string]$loadBalancingPurpose
  )

  PROCESS {
    $json = (@{
      proxyId = $proxyId;
      proxyPrefix = $proxyPrefix;
      appId = $appId;
      loadBalancingPurpose = $loadBalancingPurpose
    } | ConvertTo-Json -Compress -Depth 5)

    Post-RestUri "/qrs/loadbalancing/validengines" $json
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
    return Get-RestUri $path $filter
  }
}

function Import-QlikApp {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$file,

    [parameter(Position=1)]
    [string]$name,

    [string]$replace,
    [switch]$upload
  )

  PROCESS {
    If( $name ) {
      $appName = $name
    } Else {
      $appName = $(gci $file).BaseName
    }
    $path = "/qrs/app/{0}?name=$appName"
    If( $replace ) { $path += "&replace=$replace" }
    If( $upload ) {
      $path = $path -f 'upload'
      return UploadFile $path $file
    } else {
      $path = $path -f 'import'
      return Post-RestUri $path $file
    }
  }
}


function Import-QlikAppList {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true, Position=0)]
    [string]$pathToAppsFolder
  )
  PROCESS {
    If( Test-Path $pathToAppsFolder ) {
      $appList = dir $pathToAppsFolder *.qvf | select BaseName, Name
    } else {
      Write-Host "Exception Message: the path doesn't exist" -ForegroundColor Red
      return  
    }
    $appListSize = $appList.count
    If( $appListSize -eq 0 ) {
      Write-Host "Exception Message: there are not apps to import" -ForegroundColor Red
      return
    }
    Write-Verbose "Start AppList import..."
    Write-Verbose "Num. of apps: $appListSize"
    $count = 1
    foreach( $app in $appList ) {
      Write-Verbose "Importing app $count of $appListSize..."
      Import-QlikApp $app.BaseName "$pathToAppsFolder\$($app.Name)" -upload
      $count++
    }
    Write-Verbose "Import finished!"
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
    if($Password) { $Path += "?password=$Password" }
    return Upload-RestUri -Path $Path -FilePath $ExtensionPath
  }
}

function Import-QlikObject {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
    [PSObject[]]$object
  )

  PROCESS {
    $object | foreach {
      $path = "/qrs/{0}" -F $_.schemaPath
      $json = $_ | ConvertTo-Json -Compress -Depth 5
      Post-RestUri $path $json
    }
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
    [string]$type,
    [string[]]$tags,
    [string]$username,
    [string]$password
  )

  PROCESS {
    $json = @{
      customProperties=@();
      engineObjectId=[Guid]::NewGuid();
      username=$username;
      password=$password;
      name=$name;
      connectionstring=$connectionstring;
      type=$type
    }

    If( $tags ) {
      $prop = @(
        $tags | foreach {
          $p = Get-QlikTag -filter "name eq '$_'"
          @{
            id = $p.id
          }
        }
      )
      $json.tags = $prop
    }

    $json = $json | ConvertTo-Json -Compress -Depth 5

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
    [parameter(ValueFromPipeline=$true)]
    [PSObject]$object,

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
    If( $object ) {
      $json = $object | ConvertTo-Json -Compress -Depth 5
    } else {
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
    }

    return Post-RestUri "/qrs/systemrule" $json
  }
}

function New-QlikRulesFromFile {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true, Position=0)]
    [string]$pathToRulesFile
  )
  PROCESS {
    If( Test-Path $pathToRulesFile ) {
      $rulesContent = Get-Content $pathToRulesFile -Raw
      $ruleObjectRegex = "@{(\s)*((\w)+(\s)*=.+(\s)*)+}"
      $rules = $rulesContent | Select-String $ruleObjectRegex -AllMatches | foreach { $_.matches }
      If( $rules.count -eq 0 ) {
        Write-Host "Exception Message: there are not rules in the specified file" -ForegroundColor Red
        return 
      }
      foreach( $rule in $rules ) {
        $ruleObject = New-Object PSObject -Property $(Invoke-Expression $rule.value)
        New-QlikRule $ruleObject
      }
    } else {
      Write-Host "Exception Message: the path doesn't exist" -ForegroundColor Red
      return 
    }
  }
}

function New-QlikStream {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$name,

    [string[]]$customProperties,
    [string[]]$tags
  )

  PROCESS {
    $stream = @{
      name=$name;
    }

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
      $stream.customProperties = $prop
    }

    If( $tags ) {
      $prop = @(
        $tags | foreach {
          $p = Get-QlikTag -filter "name eq '$_'"
          @{
            id = $p.id
          }
        }
      )
      $stream.tags = $prop
    }

    $json = $stream | ConvertTo-Json -Compress -Depth 5

    return Post-RestUri '/qrs/stream' $json
  }
}

function New-QlikTag {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$name
  )

  PROCESS {
    $json = (@{
      name=$name;
    } | ConvertTo-Json -Compress -Depth 5)

    return Post-RestUri '/qrs/tag' $json
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

function Publish-QlikApp {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    [string]$id,

    [parameter(Mandatory=$true,Position=1)]
    [string]$stream,

    [string]$name
  )

  PROCESS {
    If( $stream -match $script:guid ) {
      $streamId = $stream
    } else {
      $streamId = $(Get-QlikStream -filter "name eq '$stream'").id
    }

    $path = "/qrs/app/$id/publish?stream=$streamId"

    If( $name )
    {
      $path += "&name=$name"
    }

    return Put-RestUri $path
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

function Remove-QlikApp {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/app/$id"
  }
}

function Remove-QlikCustomProperty {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/custompropertydefinition/$id"
  }
}

function Remove-QlikDataConnection {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/dataconnection/$id"
  }
}

function Remove-QlikRule {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/systemrule/$id"
  }
}

function Remove-QlikStream {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/stream/$id"
  }
}

function Remove-QlikTag {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/tag/$id"
  }
}

function Remove-QlikTask {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/task/$id"
  }
}

function Remove-QlikUser {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/user/$id"
  }
}

function Remove-QlikUserDirectory {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/userdirectory/$id"
  }
}

function Remove-QlikVirtualProxy {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Delete-RestUri "/qrs/virtualproxyconfig/$id"
  }
}

function Restore-QlikSnapshot {
  [CmdletBinding()]
  param ()
  PROCESS {
    return Post-RestUri "/qrs/sync/snapshot/restore"
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

function Update-QlikApp {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [string]$name,
    [string]$description,
    [string[]]$customProperties,
    [string[]]$tags
  )

  PROCESS {
    $app = Get-QlikApp $id
    If( $name ) { $app.name = $name }
    If( $description ) { $app.description = $description }
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
      $app.customProperties = $prop
    }

    If( $tags ) {
      $prop = @(
        $tags | foreach {
          $p = Get-QlikTag -filter "name eq '$_'"
          @{
            id = $p.id
          }
        }
      )
      $app.tags = $prop
    }

    $json = $app | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/app/$id" $json
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

function Update-QlikEngine {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [ValidateSet("IgnoreMaxLimit", "SoftMaxLimit", "HardMaxLimit")]
    [string]$workingSetSizeMode,

    [ValidateRange(0,100)]
    [Int]$workingSetSizeLoPct,

    [ValidateRange(0,100)]
    [Int]$workingSetSizeHiPct,

    [ValidateRange(0,100)]
    [Int]$cpuThrottlePercentage,

    [Bool]$AllowDataLineage,
    [Bool]$StandardReload
  )

  PROCESS {
    $engine = Get-QlikEngine -Id $id -params $params
    Write-Verbose $workingSetSizeMode
    if( $workingSetSizeMode -ne $null ) {
        switch ($workingSetSizeMode) {
            IgnoreMaxLimit { $sizeMode = 0 }
            SoftMaxLimit { $sizeMode = 1 }
            HardMaxLimit { $sizeMode = 2 }
        }
        $engine.settings.workingSetSizeMode = $sizeMode
    }
    if($workingSetSizeLoPct) {
        $engine.settings.workingSetSizeLoPct = $workingSetSizeLoPct
    }
    if($workingSetSizeHiPct) {
        $engine.settings.workingSetSizeHiPct = $workingSetSizeHiPct
    }
    if($cpuThrottlePercentage) {
        $engine.settings.cpuThrottlePercentage = $cpuThrottlePercentage
    }
    $engine.settings.allowDataLineage = $AllowDataLineage
    $engine.settings.standardReload = $StandardReload
    $json = $engine | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri -Path "/qrs/engineservice/$id" -Body $json
  }
}

function Update-QlikNode {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [string]$name,
    [ValidateSet("Production", "Development", "Both")]
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
    If( $nodePurpose ) {
        switch($nodePurpose) {
            Production { $node.nodePurpose = 0 }
            Development { $node.nodePurpose = 1 }
            Both { $node.nodePurpose = 2 }
        }
    }
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
    [Int]$RestListenPort
  )

  PROCESS {
    $proxy = Get-QlikProxy -Id $id
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
    $json = $proxy | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri -Path "/qrs/proxyservice/$id" $json
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

    $systemrule = Get-QlikRule $id -raw
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
    [string]$schedulerServiceType,

    [ValidateRange(1,256)]
    [Int]$maxConcurrentEngines,

    [ValidateRange(10,10080)]
    [Int]$engineTimeout
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
    if($maxConcurrentEngines) {
        $scheduler.settings.maxConcurrentEngines = $maxConcurrentEngines
    }
    if($engineTimeout) {
        $scheduler.settings.engineTimeout = $engineTimeout
    }
    $json = $scheduler | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri "/qrs/schedulerservice/$id" $json
  }
}

function Update-QlikReloadTask {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [Bool]$Enabled,

    [ValidateRange(1,2147483647)]
    [Int]$TaskSessionTimeout,

    [ValidateRange(0,20)]
    [Int]$MaxRetries
  )

  PROCESS {
    $task = Get-QlikReloadTask -Id $id -Params $params
    $task.enabled = $Enabled
    $task.taskSessionTimeout = $TaskSessionTimeout
    $task.maxRetries = $MaxRetries
    $json = $task | ConvertTo-Json -Compress -Depth 5
    return Put-RestUri -Path "/qrs/reloadtask/$id" -Body $json
  }
}

function Update-QlikUser {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [string[]]$customProperties,
    [string[]]$tags,
    [string[]]$roles
  )

  PROCESS {
    $user = Get-QlikUser $id -raw
    If( $roles ) { $user.roles = $roles }
    If( $customProperties ) {
      $user.customProperties = @(GetCustomProperties $customProperties)
    }
    If( $tags ) {
      $user.tags = GetTags $tags
    }
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
    [string[]]$websocketCrossOriginWhiteList,

    [String]$additionalResponseHeaders
  )

  PROCESS {
    $proxy = Get-QlikVirtualProxy $id
    If( $prefix ) { $proxy.prefix = $prefix }
    If( $description ) { $proxy.description = $description }
    If( $sessionCookieHeaderName ) { $proxy.sessionCookieHeaderName = $sessionCookieHeaderName }
    If( $psBoundParameters.ContainsKey("authenticationModuleRedirectUri") ) { $proxy.authenticationModuleRedirectUri = $authenticationModuleRedirectUri }
    If( $psBoundParameters.ContainsKey("websocketCrossOriginWhiteList") ) { $proxy.websocketCrossOriginWhiteList = $websocketCrossOriginWhiteList }
    If( $psBoundParameters.ContainsKey("additionalResponseHeaders") ) { $proxy.additionalResponseHeaders = $additionalResponseHeaders }
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

Export-ModuleMember -function Add-Qlik*, Connect-Qlik, Copy-Qlik*, Export-Qlik*, Get-Qlik*, Import-Qlik*, New-Qlik*, Publish-Qlik*, Register-Qlik*, Remove-Qlik*, Restore-Qlik*, Set-Qlik*, Start-Qlik*, Update-Qlik*, Get-RestUri
