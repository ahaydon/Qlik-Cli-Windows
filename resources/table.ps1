function New-QlikTable() {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true)]
    [string] $Type,

    [parameter(Mandatory=$true)]
    [PSObject[]] $Columns,

    [string] $Filter,
    [int] $Skip,
    [int] $Take,
    [string] $SortColumn,
    [bool] $OrderAscending
  )

  process {
    $json = @{
      type = $Type
      columns = $Columns
    } | ConvertTo-Json -Compress -Depth 10

    $path = "/qrs/$Type/table"
    $query = @(
      if ($Filter) {"filter=$Filter"}
      if ($Skip) {"skip=$Skip"}
      if ($Take) {"take=$Take"}
      if ($SortColumn) {"sortColumn=$SortColumn"}
      if ($psBoundParameters.ContainsKey("OrderAscending")) {"orderAscending=$OrderAscending"}
    ) -join '&'

    if ($query) {$path = $path, $query -join '?'}
    Return Invoke-QlikPost $path $json
  }
}
