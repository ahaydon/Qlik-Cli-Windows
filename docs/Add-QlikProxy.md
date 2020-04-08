---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version:
schema: 2.0.0
---

# Add-QlikProxy

## SYNOPSIS
Link a virtual proxy to a proxy service

## SYNTAX

```
Add-QlikProxy [-ProxyId] <String> [-VirtualProxyId] <String> [<CommonParameters>]
```

## DESCRIPTION
A virtual proxy must be linked to a proxy service before the virtual proxy is available for use.

## EXAMPLES

### Example 1: Link SAML virtual proxy to local proxy service
```powershell
PS C:\> Add-QlikProxy -ProxyId (Get-QlikProxy -id local).id -VirtualProxyId (Get-QlikVirtualProxy -filter "name eq 'SAML'").id
```

This command links a virtual proxy called SAML to the proxy service on the connected host.

## PARAMETERS

### -ProxyId
ID of the proxy service

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualProxyId
ID of the virtual proxy

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
