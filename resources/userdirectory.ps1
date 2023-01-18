function Get-QlikUserDirectory {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/userdirectory"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function New-QlikUserDirectory {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, Position = 0)]
        [string]$name,

        [parameter(Mandatory = $false, Position = 1)]
        [string]$userDirectoryName,

        [string]$type,

        [string]$configured = $false,
        [string]$syncOnlyLoggedInUsers = $true,
        [string]$syncStatus = 0,
        [string]$configuredError = "",
        [string]$operationalError = "",
        [System.Object[]]$settings = @(),
        [string[]]$tags
    )

    PROCESS {

        $ud = @{
            name = $name;
            userDirectoryName = $userDirectoryName;
            configured = $configured;
            operational = $false;
            type = $type;
            syncOnlyLoggedInUsers = $syncOnlyLoggedInUsers;
            syncStatus = $syncStatus;
            configuredError = $configuredError;
            operationalError = $operationalError;
            settings = $settings
        }
        if ($PSBoundParameters.ContainsKey("tags")) { $ud.tags = @(GetTags $tags) }
        $json = $ud | ConvertTo-Json -Compress -Depth 10

        return Invoke-QlikPost "/qrs/UserDirectory" $json
    }
}

function Remove-QlikUserDirectory {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete "/qrs/userdirectory/$id"
    }
}

function Sync-QlikUserDirectory {
    [CmdletBinding()]
    param (
        [System.Guid[]]$guid = @()
    )

    PROCESS {
        $json = ConvertTo-Json -Compress -Depth 10 $guid

        return Invoke-QlikPost "/qrs/userdirectoryconnector/syncuserdirectories" $json
    }
}

function Update-QlikUserDirectory {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "password", Justification = "Deprecation warning")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "", Justification = "Deprecation warning")]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [string]$name,
        [string]$path,
        [string]$username,
        [string]$password,
        [PSCredential]$Credential,
        [string]$ldapFilter,
        [int]$timeout,
        [Int]$pageSize,
        [object[]]$tags
    )

    PROCESS {
        if ( $username -Or $password ) {
            Write-Warning "Use of username/password parameters is deprecated, please use Credential instead."
        }
        if ( $Credential ) {
            $username = $Credential.Username
            $password = $Credential.GetNetworkCredential().Password
        }

        $ud = Get-QlikUserDirectory -id $id -raw
        if ($name) {
            $ud.name = $name
        }
        if ($path) {
            ($ud.settings | Where-Object name -EQ path).value = $path
        }
        if ($username) {
            ($ud.settings | Where-Object name -EQ 'User name').value = $username
        }
        if ($password) {
            ($ud.settings | Where-Object name -EQ password).value = $password
        }
        if ($ldapFilter) {
            ($ud.settings | Where-Object name -EQ 'LDAP Filter').value = $ldapFilter
        }
        if ($timeout) {
            ($ud.settings | Where-Object name -EQ 'Synchronization timeout in seconds').value = $timeout
        }
        if ($pageSize) {
            ($ud.settings | Where-Object name -EQ 'Page size').value = $pageSize
        }
        if ($PSBoundParameters.ContainsKey("tags")) { $ud.tags = @(GetTags $tags $ud.tags) }

        $json = $ud | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut -path "/qrs/userdirectory/$id" -body $json
    }
}
