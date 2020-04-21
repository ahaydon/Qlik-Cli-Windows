Add-Type -AssemblyName System.Web

<#
	.SYNOPSIS
		Establishes a session with a Qlik Sense server, other Qlik cmdlets will use this session to invoke commands.

	.DESCRIPTION
		Uses the parameter values to establish a new session with a Sense server, if a valid certificate can be found in the Windows certificate store it will be used unless this is overridden by the certificate parameter. If a valid certificate cannot be found Windows authentication will be attempted using the credentials of the user that is running the PowerShell console.

	.PARAMETER Computername
		 Name of the Sense server to connect to

	.PARAMETER TrustAllCerts
		 Disable checking of certificate trust

	.PARAMETER Username
		 UserId to use with certificate authentication in the format domain\username

	.PARAMETER Certificate
		 Client certificate to use for authentication

	.PARAMETER Context
		User Context for Connection

	.PARAMETER Attributes
		Any additional attributes to use on the connection request

	.PARAMETER UseDefaultCredentials
		 Use credentials of logged on user for authentication, prevents automatically locating a certificate

	.PARAMETER TimeoutSec
		Set a Global Timeout for all Rest Requests

	.EXAMPLE
		Connect-Qlik -computername CentralNodeName -username domain\username

	.LINK
		https://github.com/ahaydon/Qlik-Cli
#>
function Connect-Qlik {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param
    (
        [Parameter(Position = 0)]
        [string]$Computername,
        [switch]$TrustAllCerts,
        [Parameter(ParameterSetName = 'Certificate')]
        [string]$Username = "$($env:userdomain)\$($env:username)",
        [Parameter(ParameterSetName = 'Certificate',
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate]$Certificate,
        [Parameter(ParameterSetName = 'Certificate')]
        [ValidateSet('AppAccess', 'ManagementAccess')]
        [string]$Context = 'ManagementAccess',
        [Parameter(ParameterSetName = 'Certificate')]
        [hashtable]$Attributes,
        [Parameter(ParameterSetName = 'Default')]
        [switch]$UseDefaultCredentials,
        [int]$TimeoutSec
    )

    PROCESS {
        # Since we are connecting we need to clear any variables relating to previous connections
        $script:api_params = $null
        $script:prefix = $null
        $script:webSession = $null

        If ($TrustAllCerts -and $PSVersionTable.PSVersion.Major -lt 6) {
            if (-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
                Add-Type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
          public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
          }
        }
"@
            }
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Tls,Tls11,Tls12'
        If (!$Certificate -And !$Credential -And !$UseDefaultCredentials) {
            $certs = @(FetchCertificate "My" "CurrentUser")
            Write-Verbose "Found $($certs.Count) certificates in CurrentUser store"
            If ($certs.Count -eq 0) {
                $certs = @(FetchCertificate "My" "LocalMachine")
                Write-Verbose "Found $($certs.Count) certificates in LocalMachine store"
            }
            If ($certs.Count -gt 0) {
                $Certificate = $certs[0]
            }
        }

        If ($Certificate) {
            Write-Verbose "Using certificate $($Certificate.FriendlyName) and user $username"
            $Script:api_params = @{
                Certificate = $Certificate
                Header = @{
                    "X-Qlik-User" = $("UserDirectory={0};UserId={1}" -f $($username -split "\\"))
                }
            }
            if ($null -eq $Attributes) {
                $Script:api_params.Header."X-Qlik-Security" = "Context=$Context"
            }
            else {
                $Script:api_params.Header."X-Qlik-Security" = "Context=$Context; " -f ($Attributes.Keys.ForEach{ "$_=$($Attributes.$_)" } -join '; ')
            }

            $port = ":4242"
        }
        ElseIf ($Credential) {
            Write-Verbose $("Using credentials for {0}" -f $Credential.Username)
            $Script:api_params = @{
                Credential = $Credential
            }
        }
        Else {
            Write-Verbose "No valid certificate found, using Windows credentials"
            $Script:api_params = @{
                UseDefaultCredentials = $true
            }
        }

        if ($TrustAllCerts -and $PSVersionTable.PSVersion.Major -ge 6) {
            $Script:api_params.SkipCertificateCheck = $true
        }

        if ($TimeoutSec) { $script:api_params.TimeoutSec = $TimeoutSec }

        if (! $Computername) {
            $HostPath = 'C:\ProgramData\Qlik\Sense\Host.cfg'
            if (Test-Path $HostPath) {
                $Computername = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($(Get-Content $HostPath)))
            }
            else {
                $Computername = $env:computername
            }
        }
        If ($Computername.ToLower().StartsWith("http")) {
            $Script:prefix = $Computername
        }
        else {
            $Script:prefix = "https://" + $Computername + $port
        }

        $result = Get-QlikAbout
        return $result
    }
}
Set-Alias -Name Qonnect -Value Connect-Qlik

function Import-QlikObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSObject[]]$object
    )

    PROCESS {
        $object | ForEach-Object {
            $path = "/qrs/{0}" -F $_.schemaPath
            $json = $_ | ConvertTo-Json -Compress -Depth 10
            Invoke-QlikPost $path $json
        }
    }
}

function Invoke-QlikDelete {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$path
    )
    PROCESS {
        return CallRestUri Delete $path
    }
}

function Invoke-QlikGet {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$path,
        [parameter(Position = 1)]
        [string]$filter
    )
    PROCESS {
        If ($filter) {
            $filter = [System.Web.HttpUtility]::UrlEncode($filter)
            If ($path.contains("?")) {
                $path += "&filter=$filter"
            }
            else {
                $path += "?filter=$filter"
            }
        }

        return CallRestUri Get $path
    }
}

function Invoke-QlikPost {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$path,
        [parameter(Position = 1, ValueFromPipeline = $true)]
        [string]$body,
        [string]$contentType = "application/json; charset=utf-8"
    )
    PROCESS {
        $params = @{
            ContentType = $contentType
            Body = $body
        }

        return CallRestUri Post $path $params
    }
}

function Invoke-QlikPut {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$path,
        [parameter(Position = 1)]
        [string]$body,
        [string]$contentType = "application/json; charset=utf-8"
    )
    PROCESS {
        $params = @{
            ContentType = $contentType
            Body = $body
        }

        return CallRestUri Put $path $params
    }
}

function Invoke-QlikDownload {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$path,
        [parameter(Mandatory = $true, Position = 1)]
        [string]$filename
    )
    PROCESS {
        $params = @{
            OutFile = $filename
        }

        return CallRestUri Get $path $params
    }
}

function Invoke-QlikUpload {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$path,
        [parameter(Mandatory = $true, Position = 1)]
        [string]$filename,
        [string]$ContentType = "application/vnd.qlik.sense.app"
    )
    PROCESS {
        $params = @{
            InFile = $filename
            ContentType = $ContentType
        }

        return CallRestUri Post $path $params
    }
}

function Restore-QlikSnapshot {
    [CmdletBinding()]
    param ()
    PROCESS {
        return Invoke-QlikPost "/qrs/sync/snapshot/restore"
    }
}

function Update-QlikOdag {
    [cmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true, Position = 0)]
        [Bool]$enabled,
        [int]$maxConcurrentRequests
    )
    PROCESS {
        $rawOutput = $true
        $id = $(Invoke-QlikGet "/qrs/odagservice").id
        $odag = Invoke-QlikGet "/qrs/odagservice/$id"
        $odag.settings.enabled = $enabled
        If ($maxConcurrentRequests) { $odag.settings.maxConcurrentRequests = $maxConcurrentRequests }
        $json = $odag | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/odagservice/$id" $json
    }
}
