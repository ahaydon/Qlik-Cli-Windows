function Get-QlikCustomProperty {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/custompropertydefinition"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function New-QlikCustomProperty {
    [CmdletBinding()]
    param (
        [string]$name,
        [string]$valueType = "Text",
        [string[]]$choiceValues,

        [ValidateSet("App", "ContentLibrary", "DataConnection", "EngineService", "Extension", "ProxyService", "ReloadTask", "RepositoryService", "SchedulerService", "ServerNodeConfiguration", "Stream", "User", "UserSyncTask", "VirtualProxyConfig", IgnoreCase = $false)]
        [string[]]$objectTypes
    )

    PROCESS {
        $json = @{
            name = $name;
            valueType = $valueType;
            objectTypes = $objectTypes
        }
        if ($ChoiceValues) { $json.Add("ChoiceValues", $ChoiceValues) }
        $json = $json | ConvertTo-Json -Compress -Depth 10

        return Invoke-QlikPost "/qrs/custompropertydefinition" $json
    }
}

function Remove-QlikCustomProperty {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete "/qrs/custompropertydefinition/$id"
    }
}

function Update-QlikCustomProperty {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,
        [string]$name,
        [string]$valueType = "Text",
        [string[]]$choiceValues,

        [ValidateSet("App", "ContentLibrary", "DataConnection", "EngineService", "Extension", "ProxyService", "ReloadTask", "RepositoryService", "SchedulerService", "ServerNodeConfiguration", "Stream", "User", "UserSyncTask", "VirtualProxyConfig", IgnoreCase = $false)]
        [string[]]$objectTypes
    )

    PROCESS {
        $prop = Get-QlikCustomProperty $id -raw
        if ( $name ) { $prop.name = $name }
        if ( $valueType ) { $prop.valueType = $valueType }
        if ( $choiceValues -is [array]) { $prop.choiceValues = $choiceValues }
        if ( $objectTypes ) { $prop.objectTypes = $objectTypes }
        $json = $prop | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/custompropertydefinition/$id" $json
    }
}
