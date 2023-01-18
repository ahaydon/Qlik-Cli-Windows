function Get-QlikStream {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/stream"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function New-QlikStream {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$name,

        [object]$owner,
        [string[]]$customProperties,
        [string[]]$tags
    )

    PROCESS {
        $stream = @{
            name = $name;
        }

        if ($PSBoundParameters.ContainsKey("customProperties")) { $stream.customProperties = @(GetCustomProperties $customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $stream.tags = @(GetTags $tags) }
        if ($PSBoundParameters.ContainsKey("owner")) { $stream.owner = GetUser $owner }

        $json = $stream | ConvertTo-Json -Compress -Depth 10

        return Invoke-QlikPost '/qrs/stream' $json
    }
}

function Remove-QlikStream {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete "/qrs/stream/$id"
    }
}

function Update-QlikStream {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,
        [string]$name,
        [object]$owner,
        [object[]]$customProperties,
        [object[]]$tags
    )

    PROCESS {
        $stream = Get-QlikStream $id -raw

        if ($PSBoundParameters.ContainsKey("name")) { $stream.name = $name }
        if ($PSBoundParameters.ContainsKey("customProperties")) { $stream.customProperties = @(GetCustomProperties $customProperties $stream.customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $stream.tags = @(GetTags $tags $stream.tags) }
        if ($PSBoundParameters.ContainsKey("owner")) { $stream.owner = GetUser $owner }

        $json = $stream | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/stream/$id" $json
    }
}
