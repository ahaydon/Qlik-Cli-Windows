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

function Import-QlikContent {
  [CmdletBinding()]
  param (
    [Parameter(ParameterSetName="App")]
    [string]$AppID,
    [Parameter(ParameterSetName="Library")]
    [string]$LibraryName,
    [string]$FilePath,
    [string]$ExternalPath,
    [switch]$Overwrite
  )

  PROCESS {
    if(!$ExternalPath) {$ExternalPath = (Get-Item $FilePath).Name}
    $ExternalPath = [System.Web.HttpUtility]::UrlEncode($ExternalPath)
    switch ($PsCmdlet.ParameterSetName) {
      'App' {
        $Path = "/qrs/appcontent/$AppID/uploadfile?externalpath=$ExternalPath"
      }
      'Library' {
        $Path = "/qrs/contentlibrary/$LibraryName/uploadfile?externalpath=$ExternalPath"
      }
    }
    if($Overwrite) { $Path += "&overwrite=true" }
    $mime_type = [System.Web.MimeMapping]::GetMimeMapping((Get-Item $FilePath).FullName)
    Write-Verbose "Setting content type to $mime_type"
    return Invoke-QlikUpload $Path $FilePath -ContentType $mime_type
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
