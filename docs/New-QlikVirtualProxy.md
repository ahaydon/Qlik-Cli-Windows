---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version: https://github.com/ahaydon/Qlik-Cli
schema: 2.0.0
---

# New-QlikVirtualProxy

## SYNOPSIS
Creates a new virtual proxy configuration.

## SYNTAX

```
New-QlikVirtualProxy [[-prefix] <String>] [-description] <String> [-sessionCookieHeaderName] <String>
 [-authenticationModuleRedirectUri <String>] [-loadBalancingServerNodes <String[]>]
 [-websocketCrossOriginWhiteList <String[]>] [-additionalResponseHeaders <String>]
 [-authenticationMethod <String>] [-samlMetadataIdP <String>] [-samlHostUri <String>] [-samlEntityId <String>]
 [-samlAttributeUserId <String>] [-samlAttributeUserDirectory <String>] [-samlAttributeMap <Hashtable[]>]
 [-samlSlo] [-samlSigningAlgorithm <String>] [-jwtPublicKeyCertificate <String>] [-jwtAttributeUserId <String>]
 [-jwtAttributeUserDirectory <String>] [-jwtAttributeMap <Hashtable[]>] [-sessionInactivityTimeout <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -additionalResponseHeaders
{{ Fill additionalResponseHeaders Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -authenticationMethod
{{ Fill authenticationMethod Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Ticket, HeaderStaticUserDirectory, HeaderDynamicUserDirectory, static, dynamic, SAML, JWT

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -authenticationModuleRedirectUri
{{ Fill authenticationModuleRedirectUri Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases: authUri

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -description
{{ Fill description Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -jwtAttributeMap
{{ Fill jwtAttributeMap Description }}

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -jwtAttributeUserDirectory
{{ Fill jwtAttributeUserDirectory Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -jwtAttributeUserId
{{ Fill jwtAttributeUserId Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -jwtPublicKeyCertificate
{{ Fill jwtPublicKeyCertificate Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -loadBalancingServerNodes
{{ Fill loadBalancingServerNodes Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: engine

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -prefix
{{ Fill prefix Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -samlAttributeMap
{{ Fill samlAttributeMap Description }}

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -samlAttributeUserDirectory
{{ Fill samlAttributeUserDirectory Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -samlAttributeUserId
{{ Fill samlAttributeUserId Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -samlEntityId
{{ Fill samlEntityId Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -samlHostUri
{{ Fill samlHostUri Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -samlMetadataIdP
{{ Fill samlMetadataIdP Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -samlSigningAlgorithm
{{ Fill samlSigningAlgorithm Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: sha1, sha256

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -samlSlo
{{ Fill samlSlo Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -sessionCookieHeaderName
{{ Fill sessionCookieHeaderName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases: cookie

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -sessionInactivityTimeout
{{ Fill sessionInactivityTimeout Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -websocketCrossOriginWhiteList
{{ Fill websocketCrossOriginWhiteList Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: wsorigin

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
