function Remove-QlikSharedContent {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete -path "/qrs/sharedcontent/$id"
    }
}
