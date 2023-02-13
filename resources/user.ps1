function Get-QlikUser {
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'ID',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$id,
        [string]$filter,
        [Parameter(ParameterSetName = 'Full')]
        [switch]$full,
        [switch]$raw
    )

    BEGIN {
        $path = "/qrs/user"
        $properties = @('name', 'userDirectory', 'userId', 'id')
    }
    PROCESS {
        $CurrentPath = $path
        If ($PSBoundParameters.ContainsKey("ID")) { $CurrentPath += "/$id" }
        If ($full -eq $true) { $CurrentPath += "/full" }
        If ($raw -eq $true) { $rawOutput = $true }
        $paramInvokeQlikGet = @{
            path = $CurrentPath
            filter = $filter
        }
        $result = Invoke-QlikGet @paramInvokeQlikGet
        if (($full -eq $true) -Or ($full -eq $true) -Or $PSBoundParameters.ContainsKey("ID")) {
            return $result
        }
        else {
            return $result | Select-Object -Property $properties
        }
    }
}

function New-QlikUser {
    [CmdletBinding()]
    param (
        [string]$userId,
        [string]$userDirectory,
        [string]$name = $userId,
        [string[]]$roles,
        [string[]]$customProperties,
        [string[]]$tags
    )

    PROCESS {
        $user = @{
            userId = $userId;
            userDirectory = $userDirectory;
            name = $name
        }
        if ($roles) { $user.roles = $roles }
        if ($PSBoundParameters.ContainsKey("customProperties")) { $user.customProperties = @(GetCustomProperties $customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $user.tags = @(GetTags $tags) }
        $json = $user | ConvertTo-Json -Compress -Depth 10

        return Invoke-QlikPost "/qrs/user" $json
    }
}

function Remove-QlikUser {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete "/qrs/user/$id"
    }
}

function Update-QlikUser {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [object[]]$customProperties,
        [object[]]$tags,
        [string]$name,
        [string[]]$roles
    )

    PROCESS {
        $user = Get-QlikUser $id -raw
        If ($PSBoundParameters.ContainsKey("roles")) { $user.roles = $roles }
        If ($PSBoundParameters.ContainsKey("tags")) { $user.name = $name }
        if ($PSBoundParameters.ContainsKey("customProperties")) { $user.customProperties = @(GetCustomProperties $customProperties $user.customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $user.tags = @(GetTags $tags $user.tags) }

        $json = $user | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/user/$id" $json
    }
}
