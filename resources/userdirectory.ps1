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
