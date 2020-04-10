---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version: https://github.com/ahaydon/Qlik-Cli
schema: 2.0.0
---

# Register-QlikNode

## SYNOPSIS
Registers a new node in the cluster and deploys certificates to it.

## SYNTAX

```
Register-QlikNode [[-hostname] <String>] [-name <String>] [-nodePurpose <String>]
 [-customProperties <String[]>] [-tags <String[]>] [-engineEnabled] [-proxyEnabled] [-schedulerEnabled]
 [-printingEnabled] [-failoverCandidate] [<CommonParameters>]
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

### -customProperties
{{ Fill customProperties Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -engineEnabled
{{ Fill engineEnabled Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: engine

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -failoverCandidate
{{ Fill failoverCandidate Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: failover

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -hostname
{{ Fill hostname Description }}

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

### -name
{{ Fill name Description }}

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

### -nodePurpose
{{ Fill nodePurpose Description }}

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

### -printingEnabled
{{ Fill printingEnabled Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: printing

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -proxyEnabled
{{ Fill proxyEnabled Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: proxy

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -schedulerEnabled
{{ Fill schedulerEnabled Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: scheduler

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -tags
{{ Fill tags Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

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
