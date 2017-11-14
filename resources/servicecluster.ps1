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
