---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version: https://github.com/ahaydon/Qlik-Cli
schema: 2.0.0
---

# Wait-QlikExecution

## SYNOPSIS
Waits for a task or execution session to finish.

## SYNTAX

### Execution
```
Wait-QlikExecution [-executionId] <String> [<CommonParameters>]
```

### Task
```
Wait-QlikExecution [-taskId] <String> [<CommonParameters>]
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

### -executionId
{{ Fill executionId Description }}

```yaml
Type: String
Parameter Sets: Execution
Aliases: value

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -taskId
{{ Fill taskId Description }}

```yaml
Type: String
Parameter Sets: Task
Aliases: id

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
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
