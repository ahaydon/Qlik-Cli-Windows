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
        $customProperties | ForEach-Object {
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
        $tags | ForEach-Object {
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
