function Get-QlikObject {
    [CmdletBinding(DefaultParameterSetName = "Multi")]
    param (
        [parameter(ParameterSetName = "Single", Mandatory = $false, Position = 0)]
        [string]$id,
        [parameter(ParameterSetName = "Multi", Mandatory = $false)]
        [string]$filter,
        [parameter(ParameterSetName = "Multi", Mandatory = $false)]
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/app/object"
        If ($id) { $path += "/$id" }
        If ($full) { $path += "/full" }
        If ($raw) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function Publish-QlikObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0, ValueFromPipelinebyPropertyName = $True)]
        [string]$id
    )

    PROCESS {
        $path = "/qrs/app/object/$id/publish"

        return Invoke-QlikPut $path
    }
}

function Remove-QlikObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete "/qrs/app/object/$id"
    }
}

function Unpublish-QlikObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0, ValueFromPipelinebyPropertyName = $True)]
        [string]$id
    )

    PROCESS {
        $path = "/qrs/app/object/$id/unpublish"

        return Invoke-QlikPut $path
    }
}

function Update-QlikObject {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [string]$name,
        [object]$owner,
        [bool]$approved
    )

    PROCESS {
        $obj = Get-QlikObject $id -raw
        If ( $name ) {
            $obj.name = $name
        }
        If ($psBoundParameters.ContainsKey("approved")) { $obj.approved = $approved }

        If ($PSBoundParameters.ContainsKey("owner")) { $obj.owner = GetUser $owner }

        $json = $obj | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/app/object/$id" $json
    }
}
