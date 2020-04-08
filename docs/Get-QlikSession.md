---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version: https://github.com/ahaydon/Qlik-Cli
schema: 2.0.0
---

# Get-QlikSession

## SYNOPSIS
Gets the current User Sessions on the specified Proxy

## SYNTAX

### Default (Default)
```
Get-QlikSession [-virtualProxyPrefix <String>] [<CommonParameters>]
```

### Id
```
Get-QlikSession [-id] <String> [-virtualProxyPrefix <String>] [<CommonParameters>]
```

### User
```
Get-QlikSession [-userDirectory] <String> [-userId] <String> [-virtualProxyPrefix <String>]
 [<CommonParameters>]
```

## DESCRIPTION
This returns a session object with the corresponding SessionId.
https://help.qlik.com/en-US/sense-developer/November2018/apis/ProxyAPI/OpenAPI_Main.generated.html

## EXAMPLES

### EXAMPLE 1
```
Get-QlikSession
```

### EXAMPLE 2
```
Get-QlikSession -virtualProxyPrefix "/ProxyX1"
```

### EXAMPLE 3
```
Get-QlikSession -userDirectory Domain -userId Marc
```

### EXAMPLE 4
```
Get-QlikSession -virtualProxyPrefix "/ProxyX1" -userDirectory Domain -userId Marc
```

## PARAMETERS

### -id
This is to return the Session Object for a Specific Session ID

```yaml
Type: String
Parameter Sets: Id
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -userDirectory
The userDirecotry paramater is used as part of identitying the users sessions, must be used with userID

```yaml
Type: String
Parameter Sets: User
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -userId
The userID paramater is used as part of identitying the users sessions, must be used with userDirecotry

```yaml
Type: String
Parameter Sets: User
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -virtualProxyPrefix
Specifies the Virtual Proxy to get the sessions from

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
https://help.qlik.com/en-US/sense-developer/November2018/Subsystems/ProxyServiceAPI/Content/Sense_ProxyServiceAPI/ProxyServiceAPI-Session-Module-API-Session-Get.htm

## RELATED LINKS
