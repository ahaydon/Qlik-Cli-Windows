$script:guid = "^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$"
$script:isDate = "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"
if( $qlik_output_raw ) { $rawOutput = $true }

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

function DeepCopy($data) {
  $copy=@{}
  $data.Keys | ForEach-Object {
    $copy.Add($_, $(
      if($data.$_.GetType().Name -eq 'HashTable') {
        DeepCopy($data.$_)
      } else {
        $data.$_
      }
    ))
  }
  return $copy
}
