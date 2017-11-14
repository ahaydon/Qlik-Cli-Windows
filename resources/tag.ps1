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
