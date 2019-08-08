function Get-QlikAccessTypeInfo {
  PROCESS {
    return Invoke-QlikGet "/qrs/license/accesstypeinfo"
  }
}

function Get-QlikAnalyzerAccess {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/license/analyzerAccessType"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}
Set-Alias -Name Get-QlikAnalyserAccess -Value Get-QlikAnalyzerAccess

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

function Get-ProfessionalAccessType {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/license/professionalaccesstype"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
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

function New-QlikProfessionalAccessGroup {
  [CmdletBinding()]
  param (
    [string]$name
  )

  PROCESS {
    $json = (@{
      name=$name
    } | ConvertTo-Json -Compress -Depth 10)

    return Invoke-QlikPost "/qrs/License/ProfessionalAccessGroup" $json
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

function Remove-QlikProfessionalAccessType {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete -path "/qrs/license/professionalaccesstype/$id"
  }
}

function Remove-QlikUserAccessType {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )
  PROCESS {
    return Invoke-QlikDelete -path "/qrs/license/useraccesstype/$id"
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
