function Get-QlikScheduler {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$count,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/schedulerservice"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $count -And (-not ($id -And $full)) ) { $path += "/count" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function Update-QlikScheduler {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [ValidateSet("Master", "Slave", "MasterAndSlave")]
        [alias("type")]
        [string]$schedulerServiceType,

        [ValidateRange(1, 256)]
        [Int]$maxConcurrentEngines,

        [ValidateRange(10, 10080)]
        [Int]$engineTimeout
    )

    PROCESS {
        $scheduler = Get-QlikScheduler $id -raw
        If ($schedulerServiceType) {
            $scheduler.settings.schedulerServiceType = $schedulerServiceType
        }
        if ($maxConcurrentEngines) {
            $scheduler.settings.maxConcurrentEngines = $maxConcurrentEngines
        }
        if ($engineTimeout) {
            $scheduler.settings.engineTimeout = $engineTimeout
        }
        $json = $scheduler | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/schedulerservice/$id" $json
    }
}
