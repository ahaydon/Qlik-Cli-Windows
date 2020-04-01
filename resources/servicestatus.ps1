function Get-QlikServiceStatus {
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
        $path = "/qrs/serviceStatus"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $count -And (-not ($id -And $full)) ) { $path += "/count" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}
