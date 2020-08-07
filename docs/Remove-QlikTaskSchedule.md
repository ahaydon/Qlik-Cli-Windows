---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version:
schema: 2.0.0
---

# Remove-QlikTaskSchedule

## SYNOPSIS
Remove a specific Schdule from a reload task

## SYNTAX

```
Remove-QlikTaskSchedule [-ID] <Guid> [<CommonParameters>]
```

## DESCRIPTION
Remove a specific Task Schdule trigger from a reload task

## EXAMPLES

### Example 1
```powershell
PS C:\>  Remove-QlikTaskSchedule -id <guid>
```

## PARAMETERS

### -ID
Reload Task Schedule Trigger ID

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
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
