---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version: https://github.com/ahaydon/Qlik-Cli
schema: 2.0.0
---

# Connect-Qlik

## SYNOPSIS
Establishes a session with a Qlik Sense server, other Qlik cmdlets will use this session to invoke commands.

## SYNTAX

### Default (Default)
```
Connect-Qlik [[-Computername] <String>] [-TrustAllCerts] [-UseDefaultCredentials] [-TimeoutSec <Int32>]
 [<CommonParameters>]
```

### Certificate
```
Connect-Qlik [[-Computername] <String>] [-TrustAllCerts] [-Username <String>] -Certificate <X509Certificate>
 [-Context <String>] [-Attributes <Hashtable>] [-TimeoutSec <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Uses the parameter values to establish a new session with a Sense server, if a valid certificate can be found in the Windows certificate store it will be used unless this is overridden by the certificate parameter.
If a valid certificate cannot be found Windows authentication will be attempted using the credentials of the user that is running the PowerShell console.

## EXAMPLES

### EXAMPLE 1
```
Connect-Qlik -computername CentralNodeName -username domain\username
```

## PARAMETERS

### -Computername
Name of the Sense server to connect to

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TrustAllCerts
Disable checking of certificate trust

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Username
UserId to use with certificate authentication in the format domain\username

```yaml
Type: String
Parameter Sets: Certificate
Aliases:

Required: False
Position: Named
Default value: "$($env:userdomain)\$($env:username)"
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate
Client certificate to use for authentication

```yaml
Type: X509Certificate
Parameter Sets: Certificate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Context
{{ Fill Context Description }}

```yaml
Type: String
Parameter Sets: Certificate
Aliases:

Required: False
Position: Named
Default value: ManagementAccess
Accept pipeline input: False
Accept wildcard characters: False
```

### -Attributes
{{ Fill Attributes Description }}

```yaml
Type: Hashtable
Parameter Sets: Certificate
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseDefaultCredentials
Use credentials of logged on user for authentication, prevents automatically locating a certificate

```yaml
Type: SwitchParameter
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeoutSec
{{ Fill TimeoutSec Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/ahaydon/Qlik-Cli](https://github.com/ahaydon/Qlik-Cli)

