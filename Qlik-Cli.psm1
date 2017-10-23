$script:guid = "^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$"
$script:isDate = "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"
if( $qlik_output_raw ) { $rawOutput = $true }

###################################################################################################
# Internal helper functions
###################################################################################################

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
  Write-Verbose "Raw output: $rawOutput"
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

  if( !$rawOutput ) {
    Write-Verbose "Formatting response"
    $result = FormatOutput($result)
  }

  return $result
}

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

function FormatOutput($objects, $schemaPath) {
  Write-Debug "Resolving enums"
  If( !$Script:enums ) {
    $rawOutput = $true
    # If enums haven't been read get them and save them for later use
    $enums = Invoke-QlikGet "/qrs/about/api/enums"
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

###################################################################################################
# Cmdlets functions
###################################################################################################

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

function Add-QlikTrigger {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [alias("id")]
    [string]$taskId,
    [string[]]$OnSuccess,
    [string]$date
  )

  PROCESS {
    If( $tags ) {
      $tagArray = @(
        $tags | foreach {
          $p = Get-QlikTag -filter "name eq '$_'"
          @{
            id = $p.id
          }
        }
      )
    } else {
      $tagArray = @();
    }

    $task = Get-QlikReloadTask -id $taskId -raw

    If($date) {
      $date = Get-Date -Format yyyy-MM-ddTHH:mm:ss.000Z $date
      $update = @{
        schemaEvents = @(@{
          name = "Daily";
          enabled = $true;
          eventType = 0;
          startDate = "$date";
          expirationDate = "9999-12-30T23:59:59.999Z";
          schemaFilterDescription = @("* * - * * * * *");
          incrementDescription = "0 0 1 0";
          incrementOption = "2";
          reloadTask = @{
            id = $task.id
          }
        })
      }
    } else {
      $update = @{
        compositeEvents = @(
          @{
            name="TRANSFORM OnSuccess";
            enabled=$true;
            eventType=1;
            reloadTask = @{
              id = $task.id
            }
            timeConstraint=@{
      			  seconds = 0;
      			  minutes = 360;
      			  hours = 0;
      			  days = 0;
            };
            compositeRules=@($OnSuccess | foreach {
              @{
                ruleState=1;

                reloadTask=@{
                  id=$_
                }
              }
            });
            privileges=@("read","update","create","delete")
          }
        )
      }
    }

    $json = $update | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost "/qrs/reloadtask/update" $json
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

function Connect-Qlik {
<#
.SYNOPSIS
  Establishes a session with a Qlik Sense server, other Qlik cmdlets will use this session to invoke commands.
.DESCRIPTION
  Uses the parameter values to establish a new session with a Sense server, if a valid certificate can be found in the Windows certificate store it will be used unless this is overridden by the certificate parameter. If a valid certificate cannot be found Windows authentication will be attempted using the credentials of the user that is running the PowerShell console.
.EXAMPLE
  Connect-Qlik -computername CentralNodeName -username domain\username
.LINK
  https://github.com/ahaydon/Qlik-Cli
#>
  [CmdletBinding(DefaultParameterSetName="Certificate")]
  param (
    # Name of the Sense server to connect to
    [parameter(Position=0)]
    [string]$Computername,
    # Disable checking of certificate trust
    [switch]$TrustAllCerts,
    # UserId to use with certificate authentication in the format domain\username
    [Parameter(ParameterSetName = "Certificate")]
    [string]$Username = "$($env:userdomain)\$($env:username)",
    # Client certificate to use for authentication
    [parameter(ParameterSetName = "Certificate", ValueFromPipeline=$true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate]$Certificate,
    # Credentials to use when connecting via proxy
    [parameter(ParameterSetName = "Credential")]
    [PSCredential]$Credential,
    # Use credentials of logged on user for authentication, prevents automatically locating a certificate
    [parameter(ParameterSetName = "Default")]
    [switch]$UseDefaultCredentials
  )

  PROCESS {
    # Since we are connecting we need to clear any variables relating to previous connections
    $script:api_params = $null
    $script:prefix = $null
    $script:webSession = $null

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
    If( !$Certificate -And !$Credential -And !$UseDefaultCredentials ) {
      $certs = @(FetchCertificate "My" "CurrentUser")
      Write-Verbose "Found $($certs.Count) certificates in CurrentUser store"
      If( $certs.Count -eq 0 ) {
        $certs = @(FetchCertificate "My" "LocalMachine")
        Write-Verbose "Found $($certs.Count) certificates in LocalMachine store"
      }
      If( $certs.Count -gt 0 ) {
        $Certificate = $certs[0]
      }
    }

    If( $Certificate ) {
      Write-Verbose "Using certificate $($Certificate.FriendlyName)"

      $Script:api_params = @{
        Certificate=$Certificate
        Header=@{"X-Qlik-User" = $("UserDirectory={0};UserId={1}" -f $($username -split "\\"))}
      }
      $port = ":4242"
    } ElseIf( $Credential ) {
      Write-Verbose $("Using credentials for {0}" -f $Credential.Username)
      $Script:api_params = @{
        Credential=$Credential
      }
    } Else {
      Write-Verbose "No valid certificate found, using Windows credentials"
      $Script:api_params = @{
        UseDefaultCredentials=$true
      }
    }

    If ( $Computername ) {
      If( $Computername.ToLower().StartsWith( "http" ) ) {
        $Script:prefix = $Computername
      } else {
        $Script:prefix = "https://" + $Computername + $port
      }
    } else {
      $Script:prefix = "https://" + $env:computername + $port
    }

    $result = Get-QlikAbout
    return $result
  }
}
Set-Alias -Name Qonnect -Value Connect-Qlik

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

    return Invoke-QlikPost $path
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
    $app = (Invoke-QlikGet /qrs/app/$id/export).value
    Invoke-QlikDownload "/qrs/download/app/$id/$app/temp.qvf" $file
    Write-Verbose "Downloaded $id to $file"
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

function Get-QlikAbout {
  PROCESS {
    return Invoke-QlikGet "/qrs/about"
  }
}

function Get-QlikApp {
  [CmdletBinding(DefaultParameterSetName="Multi")]
  param (
    [parameter(ParameterSetName="Single",Mandatory=$false,Position=0)]
    [string]$id,

    [parameter(ParameterSetName="Multi",Mandatory=$false)]
    [string]$filter,

    [parameter(ParameterSetName="Multi",Mandatory=$false)]
    [switch]$full,

    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/app"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

function Get-QlikAccessTypeInfo {
  PROCESS {
    return Invoke-QlikGet "/qrs/license/accesstypeinfo"
  }
}

function Get-QlikCertificateDistributionPath {
  [CmdletBinding()]
  param (
  )

  PROCESS {
    $path = "/qrs/certificatedistribution/exportcertificatespath"
    return Invoke-QlikGet -Path $path
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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

function Get-QlikEngine {
  [CmdletBinding()]
  param (
    [parameter(Position=0, ValueFromPipelinebyPropertyName=$true)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/engineservice"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

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

function Get-QlikLicense {
  PROCESS {
    return Invoke-QlikGet "/qrs/license"
  }
}

function Get-QlikLicenseAudit {
  [CmdletBinding()]
  param (
    [string]$resourceType,
    [string]$resourceFilter,
    [string]$userFilter,
    [string]$environmentAttributes,
    [int]$userSkip,
    [int]$userTake,
    [int]$resourceSkip,
    [int]$resourceTake,
    [switch]$includeNonGrantingRules,
    [parameter(ValueFromPipelinebyPropertyName=$true)]
    [alias("id")]
    [string]$resourceId,
    [switch]$raw
  )
  PROCESS {
    $params = @{
      resourceType = $resourceType;
      resourceFilter = $resourceFilter;
      userFilter = $userFilter;
      environmentAttributes = $environmentAttributes;
      userSkip = $userSkip;
      userTake = $userTake;
      resourceSkip = $resourceSkip;
      resourceTake = $resourceTake;
    }
    If( $includeNonGrantingRules ) { $params.includeNonGrantingRules = $true }
    If( $resourceId ) { $params.resourceFilter = "id eq $resourceId" }
    $json = $params | ConvertTo-Json -Compress -Depth 10
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikPost "/qrs/systemrule/license/audit" $json
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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

function Get-QlikObject {
  [CmdletBinding(DefaultParameterSetName="Multi")]
  param (
    [parameter(ParameterSetName="Single",Mandatory=$false,Position=0)]
    [string]$id,

    [parameter(ParameterSetName="Multi",Mandatory=$false)]
    [string]$filter,

    [parameter(ParameterSetName="Multi",Mandatory=$false)]
    [switch]$full,

    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/app/object"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
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

function Get-QlikRelations {
  PROCESS {
    return Invoke-QlikGet "/qrs/about/api/relations"
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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

function Get-QlikReloadTask {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$Id,
    [string]$Filter,
    [switch]$Full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/reloadtask"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet -Path $path -Filter $filter
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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

function Get-QlikServiceCluster {
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
    $path = "/qrs/ServiceCluster"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $count -And (-not ($id -And $full)) ) { $path += "/count" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
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
      $result = Invoke-QlikGet $path $filter
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
      If( $raw ) { $rawOutput = $true }
      return Invoke-QlikGet $path $filter
    }
  }
}

function Get-QlikUser {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/user"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    $result = Invoke-QlikGet $path $filter
    if( $raw -Or $full ) {
      return $result
    } else {
      $properties = @('name','userDirectory','userId')
      #if( $full ) { $properties += @('roles','inactive','blacklisted','removedExternally') }
      return $result | select -Property $properties
    }
  }
}

function Get-QlikUserAccessType {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/license/useraccesstype"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
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
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
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
    [string]$loadBalancingPurpose,
    [switch]$raw
  )

  PROCESS {
    $json = (@{
      proxyId = $proxyId;
      proxyPrefix = $proxyPrefix;
      appId = $appId;
      loadBalancingPurpose = $loadBalancingPurpose
    } | ConvertTo-Json -Compress -Depth 10)

    If( $raw ) { $rawOutput = $true }
    Invoke-QlikPost "/qrs/loadbalancing/validengines" $json
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
      return Invoke-QlikUpload $path $file
    } else {
      $path = $path -f 'import'
      return Invoke-QlikPost $path $file
    }
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
    return Invoke-QlikUpload $Path $ExtensionPath
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
      $json = $_ | ConvertTo-Json -Compress -Depth 10
      Invoke-QlikPost $path $json
    }
  }
}

function Invoke-QlikDelete {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$path
  )
  PROCESS {
    return CallRestUri Delete $path
  }
}

function Invoke-QlikGet {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$path,
    [parameter(Position=1)]
    [string]$filter
  )
  PROCESS {
    If( $filter ) {
      If( $path.contains("?") ) {
        $path += "&filter=$filter"
      } else {
        $path += "?filter=$filter"
      }
    }

    return CallRestUri Get $path
  }
}

function Invoke-QlikPost {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$path,
    [parameter(Position=1,ValueFromPipeline=$true)]
    [string]$body,
    [string]$contentType = "application/json"
  )
  PROCESS {
    $params = @{
      ContentType = $contentType
      Body = $body
    }

    return CallRestUri Post $path $params
  }
}

function Invoke-QlikPut {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$path,
    [parameter(Position=1)]
    [string]$body
  )
  PROCESS {
    $params = @{
      ContentType = "application/json"
      Body = $body
    }

    return CallRestUri Put $path $params
  }
}

function Invoke-QlikDownload {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$path,
    [parameter(Mandatory=$true,Position=1)]
    [string]$filename
  )
  PROCESS {
    $params = @{
      OutFile = $filename
    }

    return CallRestUri Get $path $params
  }
}

function Invoke-QlikUpload {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$path,
    [parameter(Mandatory=$true,Position=1)]
    [string]$filename
  )
  PROCESS {
    $params = @{
      InFile = $filename
      ContentType = "application/vnd.qlik.sense.app"
    }

    return CallRestUri Post $path $params
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
    $json = $json | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost "/qrs/custompropertydefinition" $json
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
    [string[]]$customProperties,
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
      $json.customProperties = $prop
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

    $json = $json | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost "/qrs/dataconnection" $json
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
    [switch]$printingEnabled,

    [alias("failover")]
    [switch]$failoverCandidate
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
        failoverCandidate=$failoverCandidate.IsPresent;
      }
    } | ConvertTo-Json -Compress -Depth 10)
    $container = Invoke-QlikPost "/qrs/servernodeconfiguration/container" $json
    #Write-Host "http://localhost:4570/certificateSetup"
    return Invoke-QlikGet "/qrs/servernoderegistration/start/$($container.configuration.id)"
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
      $json = $object | ConvertTo-Json -Compress -Depth 10
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

    return Invoke-QlikPost "/qrs/systemrule" $json
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

    $json = $stream | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost '/qrs/stream' $json
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
    } | ConvertTo-Json -Compress -Depth 10)

    return Invoke-QlikPost '/qrs/tag' $json
  }
}

function New-QlikTask {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [alias("id")]
    [string]$appId,
    [parameter(Mandatory=$true,Position=1)]
    [string]$name,
    [string[]]$tags
  )

  PROCESS {
    If( $tags ) {
      $tagArray = @(
        $tags | foreach {
          $p = Get-QlikTag -filter "name eq '$_'" -raw
          @{
            id = $p.id
          }
        }
      )
    } else {
      $tagArray = @();
    }

    $task = @{
      task = @{
        name = $name;
        taskType = 0;
        enabled = $true;
        taskSessionTimeout = 1440;
        maxRetries = 0;
        tags = $tagArray;
        app = @{
          id = $appId
        };
        isManuallyTriggered = $false;
        customProperties = @()
      };
    }

    $json = $task | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost '/qrs/reloadtask/create' $json
  }
}

function New-QlikUser {
  [CmdletBinding()]
  param (
    [string]$userId,
    [string]$userDirectory,
    [string]$name = $userId,
    [string[]]$roles
  )

  PROCESS {
    $user = @{
      userId=$userId;
      userDirectory=$userDirectory;
      name=$name
    }
    if($roles) { $user.roles = $roles }
    $json = $user | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost "/qrs/user" $json
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
    } | ConvertTo-Json -Compress -Depth 10)

    return Invoke-QlikPost "/qrs/License/UserAccessGroup" $json
  }
}

function New-QlikUserDirectory {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$false,Position=0)]
    [string]$name,

    [parameter(Mandatory=$false,Position=1)]
    [string]$userDirectoryName,

    [ValidateSet('Repository.UserDirectoryConnectors.ODBC.OdbcSql', 'Repository.UserDirectoryConnectors.LDAP.ActiveDirectory')]
    [string]$type,

    [string]$configured=$false,
    [string]$syncOnlyLoggedInUsers=$true,
    [string]$syncStatus=0,
    [string]$configuredError="",
    [string]$operationalError="",
    [System.Object[]]$settings = @()
  )

  PROCESS {

    $json = (@{
      name=$name;
      userDirectoryName=$userDirectoryName;
      configured=$configured;
      operational=$false;
      type=$type;
      syncOnlyLoggedInUsers=$syncOnlyLoggedInUsers;
      syncStatus=$syncStatus;
      configuredError=$configuredError;
      operationalError=$operationalError;
      settings=$settings
    } | ConvertTo-Json -Compress -Depth 10)

    return Invoke-QlikPost "/qrs/UserDirectory" $json
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
    } | ConvertTo-Json -Compress -Depth 10)

    return Invoke-QlikPost "/qrs/virtualproxyconfig" $json
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

    return Invoke-QlikPut $path
  }
}

function Publish-QlikObject {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0,ValueFromPipelinebyPropertyName=$True)]
    [string]$id
  )

  PROCESS {
    $path = "/qrs/app/object/$id/publish"

    return Invoke-QlikPut $path
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
    return Invoke-QlikDelete "/qrs/app/$id"
  }
}

function Remove-QlikCustomProperty {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/custompropertydefinition/$id"
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

function Remove-QlikRule {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/systemrule/$id"
  }
}

function Remove-QlikStream {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/stream/$id"
  }
}

function Remove-QlikTag {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/tag/$id"
  }
}

function Remove-QlikTask {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/task/$id"
  }
}

function Remove-QlikUser {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/user/$id"
  }
}

function Remove-QlikUserDirectory {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/userdirectory/$id"
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

function Restore-QlikSnapshot {
  [CmdletBinding()]
  param ()
  PROCESS {
    return Invoke-QlikPost "/qrs/sync/snapshot/restore"
  }
}

function Select-QlikApp {
  [CmdletBinding()]
  param (
    #[parameter(Position=0)]
    #[string]$id,
    [string]$filter
    #[switch]$full,
    #[switch]$raw
  )

  PROCESS {
    $path = "/qrs/selection/app"
    #If( $id ) { $path += "/$id" }
    #If( $full ) { $path += "/full" }
    return Invoke-QlikPost "$path?$filter"
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
    Invoke-QlikPost $resource $json

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
      return Invoke-QlikPost "/qrs/task/$id/start$sync"
    } else {
      return Invoke-QlikPost "/qrs/task/start$($sync)?name=$id"
    }
  }
}

function Switch-QlikApp {
  [CmdletBinding()]
  param (
    # ID of the app that is used to replace another app
    [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    [string]$id,

    # ID of the app to be replaced
    [parameter(Mandatory=$true,Position=1)]
    [string]$appId
  )

  PROCESS {

    return Invoke-QlikPut "/qrs/app/$id/replace?app=$appId"

  }
}

function Sync-QlikUserDirectory {
  [CmdletBinding()]
  param (
    [System.Guid[]]$guid = @()
  )

  PROCESS {
    $json = ConvertTo-Json -Compress -Depth 10 $guid

    return Invoke-QlikPost "/qrs/userdirectoryconnector/syncuserdirectories" $json
  }
}

function Unpublish-QlikObject {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0,ValueFromPipelinebyPropertyName=$True)]
    [string]$id
  )

  PROCESS {
    $path = "/qrs/app/object/$id/unpublish"

    return Invoke-QlikPut $path
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
    $app = Get-QlikApp $id -raw
    If( $name ) { $app.name = $name }
    If( $description ) { $app.description = $description }
    If( $customProperties ) {
      $prop = @(
        $customProperties | foreach {
          $val = $_ -Split "="
          $p = Get-QlikCustomProperty -filter "name eq '$($val[0])'" -raw
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

    $json = $app | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/app/$id" $json
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
    $prop = Get-QlikCustomProperty $id -raw
    if( $name ) { $prop.name = $name }
    if( $valueType ) { $prop.valueType = $valueType }
    if( $choiceValues ) { $prop.choiceValues = $choiceValues }
    if( $objectTypes ) { $prop.objectTypes = $objectTypes }
    $json = $prop | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/custompropertydefinition/$id" $json
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
    $qdc = Get-QlikDataConnection -raw $id
    $qdc.connectionstring = $ConnectionString
    $json = $qdc | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/dataconnection/$id" $json
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
    [Bool]$StandardReload,
    [string]$documentDirectory,
    [Int]$documentTimeout,
    [int]$autosaveInterval,
    [int]$genericUndoBufferMaxSize
  )

  PROCESS {
    $engine = Get-QlikEngine -Id $id -raw
    Write-Verbose $workingSetSizeMode
    if( $workingSetSizeMode ) {
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
    if($documentDirectory) {
        $engine.settings.documentDirectory = $documentDirectory
    }
    if($AllowDataLineage) {
      $engine.settings.allowDataLineage = $AllowDataLineage
    }
    if($StandardReload) {
      $engine.settings.standardReload = $StandardReload
    }
    if($documentTimeout) {
      $engine.settings.documentTimeout = $documentTimeout
    }
    if($autosaveInterval) {
      $engine.settings.autosaveInterval = $autosaveInterval
    }
    if($genericUndoBufferMaxSize) {
      $engine.settings.genericUndoBufferMaxSize = $genericUndoBufferMaxSize
    }
    $json = $engine | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut -Path "/qrs/engineservice/$id" -Body $json
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
    $node = Get-QlikNode $id -raw
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
    $json = $node | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/servernodeconfiguration/$id" $json
  }
}

function Update-QlikObject {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [string]$owner,
    [bool]$approved
  )

  PROCESS {
    $obj = Get-QlikObject $id -raw
    If( $owner ) { $obj.owner = @{id=$owner} }
    If( $psBoundParameters.ContainsKey("approved") ) { $obj.approved = $approved }

    $json = $obj | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/app/object/$id" $json
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
    $json = $proxy | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/proxyservice/$id" $json
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
    [string]$rulecontext,

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

    $json = $systemrule | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/systemrule/$id" $json
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
    $json = $scheduler | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/schedulerservice/$id" $json
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
    [Int]$MaxRetries,

    [string[]]$Tags
  )

  PROCESS {
    $task = Get-QlikReloadTask -Id $id -Params $params
    $task.enabled = $Enabled
    $task.taskSessionTimeout = $TaskSessionTimeout
    $task.maxRetries = $MaxRetries
    If ($tags)
    {
      $task.tags = @(GetTags $tags)
    }
    $json = $task | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut -Path "/qrs/reloadtask/$id" -Body $json
  }
}

function Update-QlikServiceCluster {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true,Position=0)]
    [Guid] $id,

    [string] $name,
    [int] $persistenceType,
    [int] $persistenceMode,
    [string] $rootFolder,
    [string] $appFolder,
    [string] $staticContentRootFolder,
    [string] $connector32RootFolder,
    [string] $connector64RootFolder,
    [string] $archivedLogsRootFolder,
    [int] $failoverTimeout
  )

  process {
    $cluster = Get-QlikServiceCluster $id -raw
    $sp = $cluster.settings.sharedPersistenceProperties

    if ($name) { $cluster.name = $name }
    if ($persistenceType) { $cluster.settings.persistenceType = $persistenceType }
    if ($persistenceMode) { $cluster.settings.persistenceMode = $persistenceMode }
    if ($rootFolder) { $sp.rootFolder = $rootFolder }
    if ($appFolder) { $sp.appFolder = $appFolder }
    if ($staticContentRootFolder) { $sp.staticContentRootFolder = $staticContentRootFolder }
    if ($connector32RootFolder) { $sp.connector32RootFolder = $connector32RootFolder }
    if ($connector64RootFolder) { $sp.connector64RootFolder = $connector64RootFolder }
    if ($archivedLogsRootFolder) { $sp.archivedLogsRootFolder = $archivedLogsRootFolder }
    if ($failoverTimeout) { $sp.failoverTimeout = $failoverTimeout }

    $json = $cluster | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut /qrs/ServiceCluster/$id $json
  }
}

function Update-QlikStream {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
        [string]$id,

        [string[]]$customProperties,
        [string[]]$tags
    )

    PROCESS {
        $stream = Get-QlikStream $id -raw
        If( $customProperties ) {
          $stream.customProperties = @(GetCustomProperties $customProperties)
        }
        If( $tags ) {
          $stream.tags = @(GetTags $tags)
        }
        $json = $stream | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/stream/$id" $json
    }
}

function Update-QlikUser {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [string[]]$customProperties,
    [string[]]$tags,
    [string]$name,
    [string[]]$roles
  )

  PROCESS {
    $user = Get-QlikUser $id -raw
    If( $roles ) { $user.roles = $roles }
    If( $name ) { $user.name = $name }
    If( $customProperties ) {
      $user.customProperties = @(GetCustomProperties $customProperties)
    }
    If( $tags ) {
      $user.tags = GetTags $tags
    }
    $json = $user | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/user/$id" $json
  }
}

function Update-QlikUserDirectory {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [string]$name,
    [string]$path,
    [string]$username,
    [string]$password,
    [string]$ldapFilter,
    [int]$timeout,
    [Int]$pageSize
  )

  PROCESS {
    $ud = Get-QlikUserDirectory -Id $id -raw
    if($name) {
      $ud.name = $name
    }
    if($path) {
      ($ud.settings | ? name -eq path).value = $path
    }
    if($username) {
      ($ud.settings | ? name -eq 'User name').value = $username
    }
    if($password) {
      ($ud.settings | ? name -eq password).value = $password
    }
    if($ldapFilter) {
      ($ud.settings | ? name -eq 'LDAP Filter').value = $ldapFilter
    }
    if($timeout) {
      ($ud.settings | ? name -eq 'Synchronization timeout in seconds').value = $timeout
    }
    if($pageSize) {
      ($ud.settings | ? name -eq 'Page size').value = $pageSize
    }
    $json = $ud | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut -Path "/qrs/userdirectory/$id" -Body $json
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

    [String]$magicLinkFriendlyName

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
    $json = $proxy | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/virtualproxyconfig/$id" $json
  }
}

function Wait-QlikExecution {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0,ParameterSetName="Execution")]
    [alias("value")]
    [string]$executionId,

    [parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True,Position=0,ParameterSetName="Task")]
    [alias("id")]
    [string]$taskId
  )

  PROCESS {
    if ($executionId)
    {
      $execution = Invoke-QlikGet "/qrs/executionSession/$executionId"
      $resultId = $execution.executionResult.Id
      $taskName = $execution.reloadTask.name
    }
    else
    {
      $task = Invoke-QlikGet "/qrs/reloadTask/$taskId"
      $resultId = $task.operational.lastExecutionResult.id
      $taskName = $task.name
    }
    do {
        # Get task status
        $rawOutput = $true
        $result = Invoke-QlikGet "/qrs/executionResult/$resultId"

        # Get internal task status code
        $taskstatuscode = $result.status

        $result = FormatOutput($result)
        Write-Progress -Activity $taskName -Status $result.status -CurrentOperation ($result.details | select -Last 1).message

        # Wait for 1 second, in a Production setting this should be set much higher to avoid stressing the QRS API
        Start-Sleep -Seconds 1

    } until ($taskstatuscode -gt 3) #status code of more than 3 is a completion (both success and fail)
    return $result
  }
}
function Set-QlikCentral {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikPost "/qrs/failover/tonode/$id"
  }
}

function Update-QlikOdag {
  [cmdletBinding()]
  param (
      [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true,Position=0)]
      [Bool]$enabled,
      [int]$maxConcurrentRequests
      )
  PROCESS {
      $rawOutput = $true
      $id = $(Invoke-QlikGet "/qrs/odagservice").id
      $odag = Invoke-QlikGet "/qrs/odagservice/$id"
      $odag.settings.enabled = $enabled
      If ( $maxConcurrentRequests ) { $odag.settings.maxConcurrentRequests = $maxConcurrentRequests }
      $json = $odag | ConvertTo-Json -Compress -Depth 10
      return Invoke-QlikPut "/qrs/odagservice/$id" $json
      }
}

function New-QlikContentLibrary {
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

    $json = $stream | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost '/qrs/contentlibrary' $json
  }
}

function Remove-QlikContentLibrary {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/contentlibrary/$id"
  }
}


Export-ModuleMember -function Add-Qlik*, Connect-Qlik, Copy-Qlik*, Export-Qlik*, Get-Qlik*, Import-Qlik*, Invoke-Qlik*, New-Qlik*, Publish-Qlik*, Register-Qlik*, Remove-Qlik*, Restore-Qlik*, Select-Qlik*, Set-Qlik*, Start-Qlik*, Switch-Qlik*, Sync-QlikUserDirectory, Unpublish-Qlik*, Update-Qlik*, Wait-Qlik* -alias *
