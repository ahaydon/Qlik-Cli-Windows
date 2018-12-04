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
      $name = [System.Web.HttpUtility]::UrlEncode($name)
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
		[string]$filename,
		[switch]$SkipData
  )

  PROCESS {
	  if ($PSBoundParameters.ContainsKey("Skipdata")){$SkipFilter = "?skipdata=$($SkipData.IsPresent)"}else{$SkipFilter = ""}
	  Write-Verbose filename=$filename
    If( [string]::IsNullOrEmpty($filename) ) {
      $file = "$id.qvf"
    } else {
      $file = $filename
    }
    Write-Verbose file=$file
	  $guid = [guid]::NewGuid()
	  $app = Invoke-QlikPost /qrs/app/$id/export/$($guid)$SkipFilter
    Invoke-QlikDownload -path "$($app.downloadPath)" $file
    Write-Verbose "Downloaded $id to $file"
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

function Import-QlikApp {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,Position=0)]
    [string]$file,

    [parameter(Position=1)]
    [string]$name,

    [switch]$upload
  )

  PROCESS {
    If( $name ) {
      $appName = $name
    } Else {
      $appName = $(gci $file).BaseName
    }
    $appName = [System.Web.HttpUtility]::UrlEncode($appName)
    $path = "/qrs/app/{0}?name=$appName"
    If( $upload ) {
      $path = $path -f 'upload'
      return Invoke-QlikUpload $path $file
    } else {
      $path = $path -f 'import'
      return Invoke-QlikPost $path $file
    }
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
      $name = [System.Web.HttpUtility]::UrlEncode($name)
      $path += "&name=$name"
    }

    return Invoke-QlikPut $path
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

function Switch-QlikApp {
  [CmdletBinding()]
  param (
    # ID of the app that is used to replace another app
    [parameter(ParameterSetName="Param",Mandatory=$true,Position=0,ValueFromPipelinebyPropertyName=$True)]
    [string]$id,

    # ID of the app to be replaced
    [parameter(Mandatory=$true,Position=1)]
    [string]$appId,

    [parameter(ParameterSetName="Object",Mandatory=$true,ValueFromPipeline=$True)]
    $InputObject,

    [parameter(ParameterSetName="Object")]
    [switch]$Passthru
  )

  PROCESS {
    if($PsCmdlet.ParameterSetName -eq "Object") {
      $id = $InputObject.id
    }
    $result = Invoke-QlikPut "/qrs/app/$id/replace?app=$appId"
    if($Passthru) {
      return $InputObject
    } else {
      return $result
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
    [string[]]$tags,
    [string]$ownername
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

    If( $ownername ) {
      $prop = Get-QlikUser -filter "name eq '$($ownername)'"
      $app.owner = $prop
    }

    $json = $app | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/app/$id" $json
  }
}
