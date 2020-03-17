<#
	.SYNOPSIS
		Gets the current User Sessions on the specified Proxy
	
	.DESCRIPTION
		This returns a session object with the corresponding SessionId.
		https://help.qlik.com/en-US/sense-developer/November2018/apis/ProxyAPI/OpenAPI_Main.generated.html
	
	.PARAMETER id
		This is to return the Session Object for a Specific Session ID
	
	.PARAMETER userDirectory
		The userDirecotry paramater is used as part of identitying the users sessions, must be used with userID
	
	.PARAMETER userId
		The userID paramater is used as part of identitying the users sessions, must be used with userDirecotry
	
	.PARAMETER virtualProxyPrefix
		Specifies the Virtual Proxy to get the sessions from
		
	.EXAMPLE
				PS C:\> Get-QlikSession
	.EXAMPLE
				PS C:\> Get-QlikSession -virtualProxyPrefix "/ProxyX1"
	.EXAMPLE
				PS C:\> Get-QlikSession -userDirectory Domain -userId Marc 
	.EXAMPLE
				PS C:\> Get-QlikSession -virtualProxyPrefix "/ProxyX1" -userDirectory Domain -userId Marc 

	.NOTES
		Additional information about the Session API can be found
		https://help.qlik.com/en-US/sense-developer/November2018/apis/ProxyAPI/OpenAPI_Main.generated.html#19b1cf4a56294022A146C978a46f3a59
		https://help.qlik.com/en-US/sense-developer/November2018/Subsystems/ProxyServiceAPI/Content/Sense_ProxyServiceAPI/ProxyServiceAPI-Session-Module-API-Session-Get.htm

#>
function Get-QlikSession
{
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param
	(
		[Parameter(ParameterSetName = 'Id',
				   Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		[string]$id,
		[Parameter(ParameterSetName = 'User',
				   Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		[string]$userDirectory,
		[Parameter(ParameterSetName = 'User',
				   Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 1)]
		[string]$userId,
		[Alias('vp')]
		[string]$virtualProxyPrefix
	)
	
	PROCESS
	{
		$proxy = Get-QlikProxy local
		$prefix = "https://$($proxy.serverNodeConfiguration.hostName):$($proxy.settings.restListenPort)/qps"
		if ($PSBoundParameters.ContainsKey("virtualProxyPrefix")) { $prefix = "$($prefix)/$virtualProxyPrefix" }
		switch ($PSCmdlet.ParameterSetName)
		{
			USER{ $path = "$prefix/user/$userDirectory/$userId" }
			ID{ $path = "$prefix/session/$id" }
			Default { $path = "$prefix/session" }
		}
		try
		{
			$response = Invoke-QlikGet $path
		}
		catch { $response = $null }
		return $response
	}
}

<#
	.SYNOPSIS
		Kills the specified session on the specified Virtual Proxy
	
	.DESCRIPTION
		This takes a session ID as a parameter to remove it from the default proxy or the specified proxy.
		https://help.qlik.com/en-US/sense-developer/November2018/apis/ProxyAPI/OpenAPI_Main.generated.html?page=16
	
	.PARAMETER SessionId
		This is to Specify the Id of the session to be killed
	
	.PARAMETER virtualProxyPrefix
		Specifies the Virtual Proxy where to kill the sessions from
		
	.EXAMPLE
				PS C:\> Remove-QlikSession "7b8ab85e-0c85-4fcb-8e56-4ead683153fb"
	.EXAMPLE
				PS C:\> Remove-QlikSession -SessionId "7b8ab85e-0c85-4fcb-8e56-4ead683153fb" -virtualProxyPrefix "/ProxyX1"
	.EXAMPLE
				PS C:\> Get-QlikSession -userDirectory Domain -userId Marc | Foreach{Remove-QlikSession}
	
	.NOTES
		Additional information about the Session API can be found
		https://help.qlik.com/en-US/sense-developer/November2018/apis/ProxyAPI/OpenAPI_Main.generated.html#19b1cf4a56294022A146C978a46f3a59
		https://help.qlik.com/en-US/sense-developer/November2018/Subsystems/ProxyServiceAPI/Content/Sense_ProxyServiceAPI/ProxyServiceAPI-Session-Module-API-Session-Delete.htm

#>
function Remove-QlikSession
{
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName = 'SessionId',
				   Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   ValueFromPipeline=$true,
				   Position = 0)]
		[string]$SessionId,
		[Alias('vp')]
		[string]$virtualProxyPrefix
	)
	
	PROCESS
	{
		$proxy = Get-QlikProxy local
		$prefix = "https://$($proxy.serverNodeConfiguration.hostName):$($proxy.settings.restListenPort)/qps"
		if ($PSBoundParameters.ContainsKey("virtualProxyPrefix")) { $prefix = "$($prefix)/$virtualProxyPrefix" }
		$path = "$prefix/session/$SessionId" 
		
		try
		{
			$response = Invoke-QlikDelete $path
		}
		catch { $response = $null }
		return $response
	}
}