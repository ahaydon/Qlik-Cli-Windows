function Get-QlikNode {
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
        $path = "/qrs/servernodeconfiguration"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $count -And (-not ($id -And $full)) ) { $path += "/count" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function New-QlikNode {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$hostname,
        [string]$name = $hostname,
        [ValidateSet("Production", "Development", "Both", "ProductionAndDevelopment")]
        [string]$nodePurpose,
        [string[]]$customProperties,
        [string[]]$tags,

        [alias("engine")]
        [switch]$engineEnabled,

        [alias("proxy")]
        [switch]$proxyEnabled,

        [alias("scheduler")]
        [switch]$schedulerEnabled,

        [alias("printing")]
        [switch]$printingEnabled,

        [alias("failover")]
        [switch]$failoverCandidate
    )

    PROCESS {
        $conf = @{
            configuration = @{
                name = $name;
                hostName = $hostname;
            }
        }
        if ($PSBoundParameters.ContainsKey("customProperties")) { $node.customProperties = @(GetCustomProperties $customProperties $node.customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $node.tags = @(GetTags $tags $node.tags) }
        If ( $psBoundParameters.ContainsKey("failoverCandidate") ) {
            $conf.configuration.failoverCandidate = $failoverCandidate.IsPresent
            if ($failoverCandidate.IsPresent) {
                $conf.configuration.engineEnabled = $true
                $conf.configuration.proxyEnabled = $true
                $conf.configuration.schedulerEnabled = $true
                $conf.configuration.printingEnabled = $true
            }
        }
        If ( $psBoundParameters.ContainsKey("engineEnabled") ) { $conf.configuration.engineEnabled = $engineEnabled.IsPresent }
        If ( $psBoundParameters.ContainsKey("proxyEnabled") ) { $conf.configuration.proxyEnabled = $proxyEnabled.IsPresent }
        If ( $psBoundParameters.ContainsKey("schedulerEnabled") ) { $conf.configuration.schedulerEnabled = $schedulerEnabled.IsPresent }
        If ( $psBoundParameters.ContainsKey("printingEnabled") ) { $conf.configuration.printingEnabled = $printingEnabled.IsPresent }

        If ( $nodePurpose ) {
            $conf.configuration.nodePurpose = switch ($nodePurpose) {
                Production { 0 }
                Development { 1 }
                ProductionAndDevelopment { 2 }
                Both { 2 }
            }
        }
        $json = ($conf | ConvertTo-Json -Compress -Depth 10)
        $container = Invoke-QlikPost "/qrs/servernodeconfiguration/container" $json
        #Write-Host "http://localhost:4570/certificateSetup"
        return Invoke-QlikGet "/qrs/servernoderegistration/start/$($container.configuration.id)"
    }
}

function Register-QlikNode {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$hostname = $($env:computername),
        [string]$name = $hostname,
        [string]$nodePurpose,
        [string[]]$customProperties,
        [string[]]$tags,

        [alias("engine")]
        [switch]$engineEnabled,

        [alias("proxy")]
        [switch]$proxyEnabled,

        [alias("scheduler")]
        [switch]$schedulerEnabled,

        [alias("printing")]
        [switch]$printingEnabled,

        [alias("failover")]
        [switch]$failoverCandidate
    )

    PROCESS {
        If ( !$psBoundParameters.ContainsKey("hostname") ) { $psBoundParameters.Add( "hostname", $hostname ) }
        If ( !$psBoundParameters.ContainsKey("name") ) { $psBoundParameters.Add( "name", $name ) }
        $password = New-QlikNode @psBoundParameters
        if ($password) {
            $postParams = @{__pwd = "$password" }
            Invoke-WebRequest -Uri "http://localhost:4570/certificateSetup" -Method Post -Body $postParams -UseBasicParsing > $null
        }
    }
}

function Remove-QlikNode {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true, Position = 0)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete "/qrs/servernodeconfiguration/$id"
    }
}

function Update-QlikNode {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [string]$name,
        [ValidateSet("Production", "Development", "Both", "ProductionAndDevelopment")]
        [string]$nodePurpose,
        [object[]]$customProperties,
        [object[]]$tags,
        [switch]$engineEnabled,
        [switch]$proxyEnabled,
        [switch]$schedulerEnabled,
        [switch]$printingEnabled,
        [switch]$failoverCandidate
    )

    PROCESS {
        $node = Get-QlikNode $id -raw
        If ( $name ) { $node.name = $name }
        If ( $nodePurpose ) {
            switch ($nodePurpose) {
                Production { $node.nodePurpose = 0 }
                Development { $node.nodePurpose = 1 }
                ProductionAndDevelopment { $node.nodePurpose = 2 }
                Both { $node.nodePurpose = 2 }
            }
        }
        if ($PSBoundParameters.ContainsKey("customProperties")) { $node.customProperties = @(GetCustomProperties $customProperties $node.customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $node.tags = @(GetTags $tags $node.tags) }
        If ( $psBoundParameters.ContainsKey("failoverCandidate") ) {
            $node.failoverCandidate = $failoverCandidate.IsPresent
            if ($failoverCandidate.IsPresent) {
                $node.engineEnabled = $true
                $node.proxyEnabled = $true
                $node.schedulerEnabled = $true
                $node.printingEnabled = $true
            }
        }
        If ( $psBoundParameters.ContainsKey("engineEnabled") ) { $node.engineEnabled = $engineEnabled.IsPresent }
        If ( $psBoundParameters.ContainsKey("proxyEnabled") ) { $node.proxyEnabled = $proxyEnabled.IsPresent }
        If ( $psBoundParameters.ContainsKey("schedulerEnabled") ) { $node.schedulerEnabled = $schedulerEnabled.IsPresent }
        If ( $psBoundParameters.ContainsKey("printingEnabled") ) { $node.printingEnabled = $printingEnabled.IsPresent }
        $json = $node | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/servernodeconfiguration/$id" $json
    }
}
