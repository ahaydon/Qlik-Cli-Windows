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

    [object]$owner,
    [string[]]$customProperties,
    [string[]]$tags
  )

  PROCESS {
    $lib = @{
      name=$name;
    }

    if ($PSBoundParameters.ContainsKey("customProperties")) { $lib.customProperties = @(GetCustomProperties $customProperties) }
    if ($PSBoundParameters.ContainsKey("tags")) { $lib.tags = @(GetTags $tags) }
    if ($PSBoundParameters.ContainsKey("owner")) { $app.owner = GetUser $owner }

    $json = $lib | ConvertTo-Json -Compress -Depth 10

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

function Update-QlikContentLibrary {
  [CmdletBinding()]
  param (
      [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
      [string]$id,

      [object]$owner,
      [string[]]$customProperties,
      [string[]]$tags
  )

  PROCESS {
      $lib = Get-QlikContentLibrary $id -raw
      if ($PSBoundParameters.ContainsKey("customProperties")) { $lib.customProperties = @(GetCustomProperties $customProperties) }
      if ($PSBoundParameters.ContainsKey("tags")) { $lib.tags = @(GetTags $tags) }
      if ($PSBoundParameters.ContainsKey("owner")) { $lib.owner = GetUser $owner }

      $json = $lib | ConvertTo-Json -Compress -Depth 10
      return Invoke-QlikPut "/qrs/contentlibrary/$id" $json
  }
}