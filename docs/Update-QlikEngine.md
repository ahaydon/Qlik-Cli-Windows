---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version: https://github.com/ahaydon/Qlik-Cli
schema: 2.0.0
---

# Update-QlikEngine

## SYNOPSIS
Updates the properties of an engine service.

## SYNTAX

```
Update-QlikEngine [-id] <String> [-workingSetSizeMode <String>] [-workingSetSizeLoPct <Int32>]
 [-workingSetSizeHiPct <Int32>] [-cpuThrottlePercentage <Int32>] [-coresToAllocate <Int32>]
 [-AllowDataLineage <Boolean>] [-StandardReload <Boolean>] [-documentDirectory <String>]
 [-documentTimeout <Int32>] [-autosaveInterval <Int32>] [-genericUndoBufferMaxSize <Int32>]
 [-auditActivityLogVerbosity <Int32>] [-auditSecurityLogVerbosity <Int32>] [-systemLogVerbosity <Int32>]
 [-externalServicesLogVerbosity <Int32>] [-qixPerformanceLogVerbosity <Int32>] [-serviceLogVerbosity <Int32>]
 [-httpTrafficLogVerbosity <Int32>] [-auditLogVerbosity <Int32>] [-trafficLogVerbosity <Int32>]
 [-sessionLogVerbosity <Int32>] [-performanceLogVerbosity <Int32>] [-sseLogVerbosity <Int32>]
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

### -AllowDataLineage
{{ Fill AllowDataLineage Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StandardReload
{{ Fill StandardReload Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -auditActivityLogVerbosity
{{ Fill auditActivityLogVerbosity Description }}

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

### -auditLogVerbosity
{{ Fill auditLogVerbosity Description }}

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

### -auditSecurityLogVerbosity
{{ Fill auditSecurityLogVerbosity Description }}

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

### -autosaveInterval
{{ Fill autosaveInterval Description }}

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

### -coresToAllocate
{{ Fill coresToAllocate Description }}

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

### -cpuThrottlePercentage
{{ Fill cpuThrottlePercentage Description }}

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

### -documentDirectory
{{ Fill documentDirectory Description }}

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

### -documentTimeout
{{ Fill documentTimeout Description }}

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

### -externalServicesLogVerbosity
{{ Fill externalServicesLogVerbosity Description }}

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

### -genericUndoBufferMaxSize
{{ Fill genericUndoBufferMaxSize Description }}

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

### -httpTrafficLogVerbosity
{{ Fill httpTrafficLogVerbosity Description }}

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

### -id
{{ Fill id Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -performanceLogVerbosity
{{ Fill performanceLogVerbosity Description }}

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

### -qixPerformanceLogVerbosity
{{ Fill qixPerformanceLogVerbosity Description }}

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

### -serviceLogVerbosity
{{ Fill serviceLogVerbosity Description }}

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

### -sessionLogVerbosity
{{ Fill sessionLogVerbosity Description }}

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

### -sseLogVerbosity
{{ Fill sseLogVerbosity Description }}

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

### -systemLogVerbosity
{{ Fill systemLogVerbosity Description }}

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

### -trafficLogVerbosity
{{ Fill trafficLogVerbosity Description }}

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

### -workingSetSizeHiPct
{{ Fill workingSetSizeHiPct Description }}

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

### -workingSetSizeLoPct
{{ Fill workingSetSizeLoPct Description }}

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

### -workingSetSizeMode
{{ Fill workingSetSizeMode Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: IgnoreMaxLimit, SoftMaxLimit, HardMaxLimit

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
