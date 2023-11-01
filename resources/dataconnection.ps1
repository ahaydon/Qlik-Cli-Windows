function Get-QlikDataConnection {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/dataconnection"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function New-QlikDataConnection {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "password", Justification = "Deprecation warning")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "", Justification = "Deprecation warning")]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$name,
        [Parameter(ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string]$connectionstring,
        [Parameter(ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string]$type,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$customProperties,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]$tags,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$username,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$password,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$architecture,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$logOn,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]$Credential,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [object]$owner
    )

    PROCESS {
        if ($username -Or $password) {
            Write-Warning "Use of username/password parameters is deprecated, please use Credential instead."
        }
        if ($Credential) {
            $username = $Credential.Username
            $password = $Credential.GetNetworkCredential().Password
        }
        if ($password.Trim().Length -gt 0) {
            if ($password.IndexOf("%2") -eq 10) {
                $password = $password.Substring(12, $password.Length - 14)
            }
        }
        else {
            $Pass = ""
        }
        if ($username.Trim().Length -eq 0) {
            $username = ""
        }

        switch ($architecture) {
            ( { ($_ -eq "0") -or ($_ -eq "Undefined") } ) { $architecture = 0 }
            ( { ($_ -eq "1") -or ($_ -eq "x86") } ) { $architecture = 1 }
            ( { ($_ -eq "2") -or ($_ -eq "x64") } ) { $architecture = 2 }
            default { $architecture = 0 }
        }

        switch ($logOn) {
            ( { ($_ -eq "0") -or ($_ -eq "LOG_ON_SERVICE_USER") } ) { $logOn = 0 }
            ( { ($_ -eq "1") -or ($_ -eq "LOG_ON_CURRENT_USER") } ) { $logOn = 1 }
            default { $logOn = 0 }
        }

        $qdc = @{
            name = $name;
            connectionstring = $connectionstring;
            type = $type
            LogOn = $logOn
            Architecture = $architecture
            customProperties = @();
            tags = @();
            engineObjectId = [Guid]::NewGuid();
            username = $username;
            password = $password;
        }

        if ($PSBoundParameters.ContainsKey("customProperties")) { $qdc.customProperties = @(GetCustomProperties $customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $qdc.tags = @(GetTags $tags) }
        if ($PSBoundParameters.ContainsKey("owner")) { $qdc.owner = GetUser $owner }

        $json = $qdc | ConvertTo-Json -Compress -Depth 10

        return Invoke-QlikPost "/qrs/dataconnection" $json
    }
}

function Remove-QlikDataConnection {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete "/qrs/dataconnection/$id"
    }
}

function Update-QlikDataConnection {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,
        [string]$ConnectionString,
        [PSCredential]$Credential,
        [object]$owner,
        [object[]]$customProperties,
        [object[]]$tags
    )

    PROCESS {
        $qdc = Get-QlikDataConnection -raw $id
        If ($PSBoundParameters.ContainsKey("ConnectionString")) {
            $qdc.connectionstring = $ConnectionString
        }
        if ($PSBoundParameters.ContainsKey("Credential")) {
            if ($null -eq $Credential) {
                $Credential = [System.Management.Automation.PSCredential]::Empty
            }
            if ($Credential.Password -is [System.Security.SecureString]) {
                $password = $Credential.GetNetworkCredential().Password
            }
            else {
                $password = ''
            }

            $qdc.username = $Credential.Username
            if ($qdc.psobject.Properties.name -contains "password") {
                $qdc.password = $password
            }
            else {
                $qdc | Add-Member -MemberType NoteProperty -Name "password" -Value $password
            }
        }
        if ($PSBoundParameters.ContainsKey("customProperties")) { $qdc.customProperties = @(GetCustomProperties $customProperties $qdc.customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $qdc.tags = @(GetTags $tags $qdc.tags) }
        if ($PSBoundParameters.ContainsKey("owner")) { $qdc.owner = GetUser $owner }

        $json = $qdc | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/dataconnection/$id" $json
    }
}

