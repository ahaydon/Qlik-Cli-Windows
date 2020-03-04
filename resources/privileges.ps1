function Assert-QlikPrivilege {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true)]
    [object]$InputObject,
    [parameter(Position=0)]
    [string[]]$privileges
  )

  PROCESS {
    $access = @(Get-QlikPrivileges -InputObject $InputObject)
    $privileges.ForEach{
      if ($access -notcontains $_) {
        throw ("Expected '{0}' to be found in collection @('{1}'), but it was not found. {2} - {{{3}}}" -f $_, ($access -join "', '"), $InputObject.schemaPath, $InputObject.id)
      }
    }
  }
}

function Get-QlikPrivilege {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
    [object]$InputObject,
    [int]$privilegesFilter
  )

  PROCESS {
    $resourceType = $InputObject.schemaPath
    $path = "/qrs/$resourceType/previewprivileges"
    If( $privilegesFilter ) { $path += "?privilegesFilter=$privilegesFilter" }
    return Invoke-QlikPost $path ($InputObject | ConvertTo-Json -Depth 10 -Compress)
  }
}
