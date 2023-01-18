function Add-QlikProxy {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string]$ProxyId,

        [parameter(Mandatory = $true, Position = 1)]
        [string]$VirtualProxyId
    )

    PROCESS {
        $proxy = Get-QlikProxy -raw $ProxyId
        $vp = Get-QlikVirtualProxy -raw $VirtualProxyId

        $proxy.settings.virtualProxies += $vp
        $json = $proxy | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/proxyservice/$ProxyId" $json
    }
}

function Add-QlikVirtualProxy {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [alias("engine")]
        [string[]]$loadBalancingServerNodes,
        [alias("wsorigin")]
        [string[]]$websocketCrossOriginWhiteList
    )

    PROCESS {
        $proxy = Get-QlikVirtualProxy -raw $id
        $params = $psBoundParameters
        If ( $params.ContainsKey("loadBalancingServerNodes") ) {
            $params["loadBalancingServerNodes"] = @( $proxy.loadBalancingServerNodes | ForEach-Object { $_.id } ) + $loadBalancingServerNodes
        }
        If ( $params.ContainsKey("websocketCrossOriginWhiteList") ) {
            $params["websocketCrossOriginWhiteList"] = $proxy.websocketCrossOriginWhiteList + $websocketCrossOriginWhiteList
        }
        return Update-QlikVirtualProxy @params
    }
}

function Export-QlikMetadata {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true, Position = 0)]
        [string]$id,
        [parameter(Position = 1)]
        [string]$filename
    )

    PROCESS {
        Write-Verbose filename=$filename
        If ( [string]::IsNullOrEmpty($filename) ) {
            $vp = Get-QlikVirtualProxy -id $id -raw
            $file = "$($vp.prefix)_metadata_sp.xml"
        }
        else {
            $file = $filename
        }
        Write-Verbose file=$file
        $export = (Invoke-QlikGet "/qrs/virtualproxyconfig/$id/generate/samlmetadata").value
        $basename = $file
        if ( $basename.IndexOf('/') -gt 0 ) {
            $basename = $basename.SubString($basename.LastIndexOf('/') + 1)
        }
        if ( $basename.IndexOf('\') -gt 0 ) {
            $basename = $basename.SubString($basename.LastIndexOf('\') + 1)
        }
        Invoke-QlikDownload "/qrs/download/samlmetadata/$export/$basename" $file
        Write-Verbose "Downloaded $id to $file"
    }
}

function Get-QlikProxy {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/proxyservice"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function Get-QlikVirtualProxy {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/virtualproxyconfig"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function New-QlikVirtualProxy {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$prefix,

        [parameter(Mandatory = $true, Position = 1)]
        [string]$description,

        [parameter(Mandatory = $true, Position = 2)]
        [alias("cookie")]
        [string]$sessionCookieHeaderName,

        [alias("authUri")]
        [string]$authenticationModuleRedirectUri,

        [alias("engine")]
        [string[]]$loadBalancingServerNodes = "",

        [alias("wsorigin")]
        [string[]]$websocketCrossOriginWhiteList = "",

        [String]$additionalResponseHeaders = "",
        [Int]$sessionInactivityTimeout = 30,

        [ValidateSet("Ticket", "HeaderStaticUserDirectory", "HeaderDynamicUserDirectory", "static", "dynamic", "SAML", "JWT", "OIDC", IgnoreCase = $false)]
        [String]$authenticationMethod = "Ticket",

        [String]$samlMetadataIdP = "",
        [String]$samlHostUri = "",
        [String]$samlEntityId = "",
        [String]$samlAttributeUserId = "",
        [String]$samlAttributeUserDirectory = "",
        [hashtable[]]$samlAttributeMap = @(),
        [switch]$samlSlo,
        [ValidateSet("sha1", "sha256")]
        [String]$samlSigningAlgorithm = "sha1",

        [String]$jwtPublicKeyCertificate = "",
        [String]$jwtAttributeUserId = "",
        [String]$jwtAttributeUserDirectory = "",
        [hashtable[]]$jwtAttributeMap = @(),

        [string]$oidcConfigurationEndpointUri,
        [string]$oidcClientId,
        [string]$oidcClientSecret,
        [string]$oidcRealm,
        [string]$oidcAttributeSub,
        [string]$oidcAttributeName,
        [string]$oidcAttributeGroups,
        [string]$oidcAttributeEmail,
        [string]$oidcAttributeClientId,
        [string]$oidcAttributePicture,
        [hashtable[]]$oidcAttributeMap = @(),
        [string]$oidcScope
    )

    PROCESS {
        If ( $loadBalancingServerNodes ) {
            $engines = @(
                $loadBalancingServerNodes | ForEach-Object {
                    If ( $_ -match $script:guid ) {
                        @{ id = $_ }
                    }
                    else {
                        $eid = Get-QlikNode -filter "hostname eq '$_'"
                        @{ id = $eid.id }
                    }
                }
            )
        }
        else {
            $engines = @()
        }
        $authenticationMethodCode = switch ($authenticationMethod) {
            "ticket" { 0 }
            "static" { 1 }
            "dynamic" { 2 }
            "saml" { 3 }
            "jwt" { 4 }
            "oidc" { 5 }
            default { $authenticationMethod }
        }
        $samlSigningAlgorithmCode = switch ($samlSigningAlgorithm) {
            "sha1" { 0 }
            "sha256" { 1 }
        }

        $json = (@{
                prefix = $prefix;
                description = $description;
                authenticationModuleRedirectUri = $authenticationModuleRedirectUri;
                loadBalancingServerNodes = $engines;
                sessionCookieHeaderName = $sessionCookieHeaderName;
                websocketCrossOriginWhiteList = $websocketCrossOriginWhiteList;
                additionalResponseHeaders = $additionalResponseHeaders;
                sessionInactivityTimeout = $sessionInactivityTimeout;
                authenticationMethod = $authenticationMethodCode;
                samlMetadataIdP = $samlMetadataIdP;
                samlHostUri = $samlHostUri;
                samlEntityId = $samlEntityId;
                samlAttributeUserId = $samlAttributeUserId;
                samlAttributeUserDirectory = $samlAttributeUserDirectory;
                samlAttributeMap = $samlAttributeMap;
                samlSlo = $samlSlo.IsPresent;
                samlAttributeSigningAlgorithm = $samlSigningAlgorithmCode;
                jwtPublicKeyCertificate = $jwtPublicKeyCertificate;
                jwtAttributeUserId = $jwtAttributeUserId;
                jwtAttributeUserDirectory = $jwtAttributeUserDirectory;
                jwtAttributeMap = $jwtAttributeMap;
                oidcConfigurationEndpointUri = $oidcConfigurationEndpointUri;
                oidcClientId = $oidcClientId;
                oidcClientSecret = $oidcClientSecret;
                oidcRealm = $oidcRealm;
                oidcAttributeSub = $oidcAttributeSub;
                oidcAttributeName = $oidcAttributeName;
                oidcAttributeGroups = $oidcAttributeGroups;
                oidcAttributeEmail = $oidcAttributeEmail;
                oidcAttributeClientId = $oidcAttributeClientId;
                oidcAttributePicture = $oidcAttributePicture;
                oidcAttributeMap = $oidcAttributeMap;
                oidcScope = $oidcScope;
            } | ConvertTo-Json -Compress -Depth 10)

        return Invoke-QlikPost "/qrs/virtualproxyconfig" $json
    }
}

function Remove-QlikVirtualProxy {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete "/qrs/virtualproxyconfig/$id"
    }
}

function Update-QlikProxy {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [ValidateRange(1, 65536)]
        [Int]$ListenPort,

        [Bool]$AllowHttp,

        [ValidateRange(1, 65536)]
        [Int]$UnencryptedListenPort,

        [ValidateRange(1, 65536)]
        [Int]$AuthenticationListenPort,

        [Bool]$KerberosAuthentication,

        [ValidateRange(1, 65536)]
        [Int]$UnencryptedAuthenticationListenPort,

        [String]$SslBrowserCertificateThumbprint,

        [ValidateRange(1, 300)]
        [Int]$KeepAliveTimeoutSeconds,

        [ValidateRange(512, 131072)]
        [Int]$MaxHeaderSizeBytes,

        [ValidateRange(20, 1000)]
        [Int]$MaxHeaderLines,

        [ValidateRange(1, 65536)]
        [Int]$RestListenPort,

        [String[]]$customProperties,

        [String[]]$virtualProxies
    )

    PROCESS {
        $proxy = Get-QlikProxy -raw -id $id
        if ($listenPort) { $proxy.settings.listenPort = $listenPort }
        $proxy.settings.allowHttp = $allowHttp
        if ($unencryptedListenPort) { $proxy.settings.unencryptedListenPort = $unencryptedListenPort }
        if ($authenticationListenPort) { $proxy.settings.authenticationListenPort = $authenticationListenPort }
        $proxy.settings.kerberosAuthentication = $kerberosAuthentication
        if ($unencryptedAuthenticationListenPort) { $proxy.settings.unencryptedAuthenticationListenPort = $unencryptedAuthenticationListenPort }
        if ($sslBrowserCertificateThumbprint) { $proxy.settings.sslBrowserCertificateThumbprint = $sslBrowserCertificateThumbprint }
        if ($keepAliveTimeoutSeconds) { $proxy.settings.keepAliveTimeoutSeconds = $keepAliveTimeoutSeconds }
        if ($maxHeaderSizeBytes) { $proxy.settings.maxHeaderSizeBytes = $maxHeaderSizeBytes }
        if ($maxHeaderLines) { $proxy.settings.maxHeaderLines = $maxHeaderLines }
        if ($restListenPort) { $proxy.settings.restListenPort = $restListenPort }
        If ( $customProperties ) {
            $prop = @(
                $customProperties | ForEach-Object {
                    $val = $_ -Split "="
                    $p = Get-QlikCustomProperty -filter "name eq '$($val[0])'"
                    @{
                        value = ($p.choiceValues -eq $val[1])[0]
                        definition = $p
                    }
                }
            )
            $proxy.customProperties = $prop
        }
        If ( $null -ne $virtualProxies ) {
            $set = New-Object System.Collections.Generic.HashSet[string]
            $virtualProxies | ForEach-Object {
                If ( $_ -match $script:guid ) {
                    $res = $set.Add($_)
                }
                elseif ($_ -ne '') {
                    $eid = Get-QlikVirtualProxy -filter "prefix eq '$_'"
                    If ( $eid ) {
                        $res = $set.Add($eid.id)
                    }
                }
            }
            $proxy.settings.virtualProxies | ForEach-Object {
                If ($_.defaultVirtualProxy) {
                    $res = $set.Add($_.id)
                }
            }
            $vProxies = @(
                $set | ForEach-Object {
                    @{ id = $_ }
                }
            )
            $proxy.settings.virtualProxies = $vProxies
        }
        $json = $proxy | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/proxyservice/$id" $json
    }
}

function Update-QlikVirtualProxy {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [string]$prefix,
        [string]$description,

        [alias("cookie")]
        [string]$sessionCookieHeaderName,

        [alias("authUri")]
        [string]$authenticationModuleRedirectUri,

        [alias("winAuthPattern")]
        [string]$windowsAuthenticationEnabledDevicePattern,

        [parameter()]
        [alias("engine")]
        [string[]]$loadBalancingServerNodes,

        [alias("wsorigin")]
        [string[]]$websocketCrossOriginWhiteList,

        [ValidateSet("Ticket", "HeaderStaticUserDirectory", "HeaderDynamicUserDirectory", "static", "dynamic", "SAML", "JWT", "OIDC", IgnoreCase = $false)]
        [String]$authenticationMethod,

        [String]$additionalResponseHeaders,
        [Int]$anonymousAccessMode,
        [String]$magicLinkHostUri,
        [String]$magicLinkFriendlyName,
        [Int]$sessionInactivityTimeout,
        [object[]]$customProperties,
        [object[]]$tags,

        [String]$samlMetadataIdP,
        [String]$samlHostUri,
        [String]$samlEntityId,
        [String]$samlAttributeUserId,
        [String]$samlAttributeUserDirectory,
        [hashtable[]]$samlAttributeMap,
        [switch]$samlSlo,
        [ValidateSet("sha1", "sha256")]
        [String]$samlSigningAlgorithm,

        [String]$jwtPublicKeyCertificate,
        [String]$jwtAttributeUserId,
        [String]$jwtAttributeUserDirectory,
        [hashtable[]]$jwtAttributeMap,

        [string]$oidcConfigurationEndpointUri,
        [string]$oidcClientId,
        [string]$oidcClientSecret,
        [string]$oidcRealm,
        [string]$oidcAttributeSub,
        [string]$oidcAttributeName,
        [string]$oidcAttributeGroups,
        [string]$oidcAttributeEmail,
        [string]$oidcAttributeClientId,
        [string]$oidcAttributePicture,
        [hashtable[]]$oidcAttributeMap = @(),
        [string]$oidcScope
    )

    PROCESS {
        $proxy = Get-QlikVirtualProxy -raw $id
        If ( $prefix ) { $proxy.prefix = $prefix }
        If ( $description ) { $proxy.description = $description }
        If ( $sessionCookieHeaderName ) { $proxy.sessionCookieHeaderName = $sessionCookieHeaderName }
        If ( $psBoundParameters.ContainsKey("authenticationModuleRedirectUri") ) { $proxy.authenticationModuleRedirectUri = $authenticationModuleRedirectUri }
        If ( $psBoundParameters.ContainsKey("websocketCrossOriginWhiteList") ) { $proxy.websocketCrossOriginWhiteList = $websocketCrossOriginWhiteList }
        If ( $psBoundParameters.ContainsKey("additionalResponseHeaders") ) { $proxy.additionalResponseHeaders = $additionalResponseHeaders }
        If ( $psBoundParameters.ContainsKey("anonymousAccessMode") ) { $proxy.anonymousAccessMode = $anonymousAccessMode }
        If ( $psBoundParameters.ContainsKey("windowsAuthenticationEnabledDevicePattern") ) { $proxy.windowsAuthenticationEnabledDevicePattern = $windowsAuthenticationEnabledDevicePattern }
        If ( $psBoundParameters.ContainsKey("loadBalancingServerNodes") ) {
            $engines = @(
                $loadBalancingServerNodes | ForEach-Object {
                    If ( $_ -match $script:guid ) {
                        @{ id = $_ }
                    }
                    else {
                        $eid = Get-QlikNode -filter "hostname eq '$_'"
                        If ( $eid ) {
                            @{ id = $eid.id }
                        }
                    }
                }
            )
            $proxy.loadBalancingServerNodes = $engines
        }
        If ( $psBoundParameters.ContainsKey("magicLinkHostUri") ) { $proxy.magicLinkHostUri = $magicLinkHostUri }
        If ( $psBoundParameters.ContainsKey("magicLinkFriendlyName") ) { $proxy.magicLinkFriendlyName = $magicLinkFriendlyName }
        If ( $psBoundParameters.ContainsKey("sessionInactivityTimeout") ) { $proxy.sessionInactivityTimeout = $sessionInactivityTimeout }
        if ($PSBoundParameters.ContainsKey("customProperties")) { $proxy.customProperties = @(GetCustomProperties $customProperties $proxy.customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $proxy.tags = @(GetTags $tags $proxy.tags) }
        If ( $psBoundParameters.ContainsKey("authenticationMethod") ) {
            $proxy.authenticationMethod = switch ($authenticationMethod) {
                "ticket" { 0 }
                "static" { 1 }
                "dynamic" { 2 }
                "saml" { 3 }
                "jwt" { 4 }
                "oidc" { 5 }
                default { $authenticationMethod }
            }
        }

        If ( $psBoundParameters.ContainsKey("samlMetadataIdP") ) { $proxy.samlMetadataIdP = $samlMetadataIdP }
        If ( $psBoundParameters.ContainsKey("samlHostUri") ) { $proxy.samlHostUri = $samlHostUri }
        If ( $psBoundParameters.ContainsKey("samlEntityId") ) { $proxy.samlEntityId = $samlEntityId }
        If ( $psBoundParameters.ContainsKey("samlAttributeUserId") ) { $proxy.samlAttributeUserId = $samlAttributeUserId }
        If ( $psBoundParameters.ContainsKey("samlAttributeUserDirectory") ) { $proxy.samlAttributeUserDirectory = $samlAttributeUserDirectory }
        If ( $psBoundParameters.ContainsKey("samlAttributeMap") ) { $proxy.samlAttributeMap = $samlAttributeMap }
        If ( $psBoundParameters.ContainsKey("samlSigningAlgorithm") ) {
            $proxy.samlAttributeSigningAlgorithm = switch ($samlSigningAlgorithm) {
                "sha1" { 0 }
                "sha256" { 1 }
            }
        }
        If ( $psBoundParameters.ContainsKey("samlSlo") ) { $proxy.samlSlo = $samlSlo.IsPresent }

        If ( $psBoundParameters.ContainsKey("jwtPublicKeyCertificate") ) { $proxy.jwtPublicKeyCertificate = $jwtPublicKeyCertificate }
        If ( $psBoundParameters.ContainsKey("jwtAttributeUserId") ) { $proxy.jwtAttributeUserId = $jwtAttributeUserId }
        If ( $psBoundParameters.ContainsKey("jwtAttributeUserDirectory") ) { $proxy.jwtAttributeUserDirectory = $jwtAttributeUserDirectory }
        If ( $psBoundParameters.ContainsKey("jwtAttributeMap") ) { $proxy.jwtAttributeMap = $jwtAttributeMap }

        If ( $psBoundParameters.ContainsKey("oidcConfigurationEndpointUri") ) { $proxy.oidcConfigurationEndpointUri = $oidcConfigurationEndpointUri }
        If ( $psBoundParameters.ContainsKey("oidcClientId") ) { $proxy.oidcClientId = $oidcClientId }
        If ( $psBoundParameters.ContainsKey("oidcClientSecret") ) { $proxy.oidcClientSecret = $oidcClientSecret }
        If ( $psBoundParameters.ContainsKey("oidcRealm") ) { $proxy.oidcRealm = $oidcRealm }
        If ( $psBoundParameters.ContainsKey("oidcAttributeSub") ) { $proxy.oidcAttributeSub = $oidcAttributeSub }
        If ( $psBoundParameters.ContainsKey("oidcAttributeName") ) { $proxy.oidcAttributeName = $oidcAttributeName }
        If ( $psBoundParameters.ContainsKey("oidcAttributeGroups") ) { $proxy.oidcAttributeGroups = $oidcAttributeGroups }
        If ( $psBoundParameters.ContainsKey("oidcAttributeEmail") ) { $proxy.oidcAttributeEmail = $oidcAttributeEmail }
        If ( $psBoundParameters.ContainsKey("oidcAttributeClientId") ) { $proxy.oidcAttributeClientId = $oidcAttributeClientId }
        If ( $psBoundParameters.ContainsKey("oidcAttributePicture") ) { $proxy.oidcAttributePicture = $oidcAttributePicture }
        If ( $psBoundParameters.ContainsKey("oidcAttributeMap") ) { $proxy.oidcAttributeMap = $oidcAttributeMap }
        If ( $psBoundParameters.ContainsKey("oidcScope") ) { $proxy.oidcScope = $oidcScope }

        $json = $proxy | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/virtualproxyconfig/$id" $json
    }
}
