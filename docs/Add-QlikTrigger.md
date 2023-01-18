---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version:
schema: 2.0.0
---

# Add-QlikTrigger

## SYNOPSIS
Create a task trigger

## SYNTAX

### CompositeEvent
```
Add-QlikTrigger [-taskId] <String> [-name <String>] [-OnSuccess <String[]>] [<CommonParameters>]
```

### SchemaEvent
```
Add-QlikTrigger [-taskId] <String> [-name <String>] [-startDate <DateTime>] [-expirationDate <DateTime>]
 [-timeZone <String>] [-daylightSavingTime <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
There are two types of triggers for a reload task:
- Composite event

  This event is triggered on condition of other events succeeding or failing, also known as task event trigger.

- Schema event

  This event is triggered according to a schedule (covers once-only as well as all repeating triggers).

## EXAMPLES

### Example 1: Trigger task on completion of another task
```powershell
PS C:\> Get-QlikTask -filter "name eq 'Reload Dashboard'" -full | Add-QlikTrigger -name 'On completion of extract' -OnSuccess (Get-QlikTask -filter "name eq 'Extract to QVD'")
```

This command creates a trigger for the 'Reload Dashboard' task that triggers on successful completion of the 'Extract to QVD' task.

### Example 2: Trigger task at a specified time every day
```powershell
PS C:\> Get-QlikTask -filter "name eq 'Extract to QVD'" -full | Add-QlikTrigger -name 'On completion of extract' -startDate (Get-Date)
```

This command creates a trigger for the 'Extract to QVD' task that triggers at the current time every day.

## PARAMETERS

### -OnSuccess
IDs of tasks for which a success should invoke this trigger

```yaml
Type: String[]
Parameter Sets: CompositeEvent
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -daylightSavingTime
{{ Fill daylightSavingTime Description }}

```yaml
Type: Boolean
Parameter Sets: SchemaEvent
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -expirationDate
End time and date

```yaml
Type: DateTime
Parameter Sets: SchemaEvent
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -name
Name of the trigger

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

### -startDate
Start time and date

```yaml
Type: DateTime
Parameter Sets: SchemaEvent
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -taskId
ID of the task to be triggered

```yaml
Type: String
Parameter Sets: (All)
Aliases: id

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -timeZone
{{ Fill timeZone Description }}

```yaml
Type: String
Parameter Sets: SchemaEvent
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

### System.String

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
