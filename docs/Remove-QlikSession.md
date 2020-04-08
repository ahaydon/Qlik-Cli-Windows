---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version:
schema: 2.0.0
---

# Remove-QlikSession

## SYNOPSIS
Kills the specified session on the specified Virtual Proxy

## SYNTAX

```
Remove-QlikSession [-SessionId] <String> [-virtualProxyPrefix <String>] [<CommonParameters>]
```

## DESCRIPTION
This takes a session ID as a parameter to remove it from the default proxy or the specified proxy.
https://help.qlik.com/en-US/sense-developer/November2018/apis/ProxyAPI/OpenAPI_Main.generated.html?page=16

## EXAMPLES

### EXAMPLE 1
```
Remove-QlikSession "7b8ab85e-0c85-4fcb-8e56-4ead683153fb"
```

### EXAMPLE 2
```
Remove-QlikSession -SessionId "7b8ab85e-0c85-4fcb-8e56-4ead683153fb" -virtualProxyPrefix "/ProxyX1"
```

### EXAMPLE 3
```
Get-QlikSession -userDirectory Domain -userId Marc | Foreach{Remove-QlikSession}
```

## PARAMETERS

### -SessionId
This is to Specify the Id of the session to be killed

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -virtualProxyPrefix
Specifies the Virtual Proxy where to kill the sessions from

```yaml
Type: String
Parameter Sets: (All)
Aliases: vp

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Additional information about the Session API can be found
https://help.qlik.com/en-US/sense-developer/November2018/apis/ProxyAPI/OpenAPI_Main.generated.html#19b1cf4a56294022A146C978a46f3a59
https://help.qlik.com/en-US/sense-developer/November2018/Subsystems/ProxyServiceAPI/Content/Sense_ProxyServiceAPI/ProxyServiceAPI-Session-Module-API-Session-Delete.htm

## RELATED LINKS
