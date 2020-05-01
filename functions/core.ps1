$script:guid = "^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$"
$script:isDate = "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"
$script:webSessionContainer =  $null
if ($qlik_output_raw) { $rawOutput = $true }


function CallRestUri {
    param
    (
        $method,
        $path,
        $extraParams
    )

    Write-Verbose "Raw output: $rawOutput"
    If ($null -eq $Script:prefix) { Connect-Qlik > $null }
    If (! $path.StartsWith("http")) {
        $path = $Script:prefix + $path
    }

    $xrfKey = GetXrfKey
    If ($path.contains("?")) {
        $path += "&xrfkey=$xrfKey"
    }
    else {
        $path += "?xrfkey=$xrfKey"
    }

    $params = DeepCopy $api_params

    If ($extraParams) { $params += $extraParams }
    If (!$params.Header) {
        $params.Header = @{ }
    }
    If (!$params.Header.ContainsKey("x-Qlik-Xrfkey")) {
        Write-Verbose "Adding header x-Qlik-Xrfkey: $xrfKey"
        $params.Header.Add("x-Qlik-Xrfkey", $xrfKey)
    }
    If ($params.Body) { Write-Verbose $params.Body }

    Write-Verbose "Calling $method for $path"

    try {
        $paramInvokeRestMethod = @{
            Method = $method
            Uri = $path
        }

        If ($null -eq $script:webSessionContainer) {
            $paramInvokeRestMethod.SessionVariable = 'webSession'
        }
        else {
            $paramInvokeRestMethod.WebSession = $script:webSessionContainer
        }

        if ($params.OutFile -or $params.InFile) {
            $ProgressPreference = 'SilentlyContinue'
            if ($null -eq $params.TimeoutSec) {
                $paramInvokeRestMethod.TimeoutSec = 300
            }
        }

        $result = Invoke-RestMethod @paramInvokeRestMethod @params
        if ($null -ne $webSession){
            $script:webSessionContainer = $webSession
        }
    }
    catch {
        throw $_
        return
    }

    if (!$rawOutput) {
        Write-Verbose "Formatting response"
        $result = FormatOutput($result)
    }
    return $result
}

function DeepCopy {
    param
    (
        $data
    )

    $copy = @{ }
    $data.Keys | ForEach-Object {
        $copy.Add($_, $(
                if ($data.$_.GetType().Name -eq 'HashTable') {
                    DeepCopy($data.$_)
                }
                else {
                    $data.$_
                }
            ))
    }
    return $copy
}
