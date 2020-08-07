---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version:
schema: 2.0.0
---

# New-QlikTaskSchedule

## SYNOPSIS
Adds a new Reload Task Schedule Trigger

## SYNTAX

### Default (Default)
```
New-QlikTaskSchedule [-Name <String>] [-RepeatEvery <Int32>] [-StartDate <DateTime>]
 [-expirationDate <DateTime>] [-DaysOfWeek <String[]>] [-DaysOfMonth <String[]>] [-TimeZone <Object>]
 [-DaylightSavingTime] [<CommonParameters>]
```

### TaskName
```
New-QlikTaskSchedule [-Name <String>] -Repeat <String> [-RepeatEvery <Int32>] [-StartDate <DateTime>]
 [-expirationDate <DateTime>] [-DaysOfWeek <String[]>] [-DaysOfMonth <String[]>] [-TimeZone <Object>]
 [-DaylightSavingTime] -ReloadTaskName <String> [<CommonParameters>]
```

### TaskID
```
New-QlikTaskSchedule [-Name <String>] [-Repeat <String>] [-RepeatEvery <Int32>] [-StartDate <DateTime>]
 [-expirationDate <DateTime>] [-DaysOfWeek <String[]>] [-DaysOfMonth <String[]>] [-TimeZone <Object>]
 [-DaylightSavingTime] -ReloadTaskID <String> [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> New-QlikTaskSchedule -Repeat Daily -RepeatEvery 2 -StartDate $(get-date) -expirationDate "8/22/2024" -ReloadTaskName "Reload Operations Monitor"
```

Adds a reload trigger to the Operations Monitor Reload Task, to run every two days

### Example 2
```powershell
PS C:\> New-QlikTaskSchedule -Repeat Weekly -Name "Weekday - MT" -DaysOfWeek Monday, Tuesday -ReloadTaskName "Reload Operations Monitor"
```

Adds a reload trigger to the Operations Monitor Reload Task, to run every week on Mondays and Tuesdays

### Example 3
```powershell
PS C:\> New-QlikTaskSchedule -Repeat "Monthly" -Name "Monthly 179121418" -DaysOfMonth 1, 7, 9, 12, 14, 18 -ReloadTaskID "1300b68c-c82c-4189-a20f-4bc4e2830072"
```

Adds a reload trigger to the Reload Task identified by ID, to run every month on specific dates in the month

## PARAMETERS

### -DaylightSavingTime
If the schedule should adhere to daylight savings time

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

### -DaysOfMonth
Days of the month for the schedule

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

### -DaysOfWeek
Days of the Week for the task to run

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:
Accepted values: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of the Trigger

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

### -ReloadTaskID
ID of the Task to associate the new schedule to

```yaml
Type: String
Parameter Sets: TaskID
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReloadTaskName
Name of the Task to associate the new schedule to

```yaml
Type: String
Parameter Sets: TaskName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Repeat
How often to run the schedule

```yaml
Type: String
Parameter Sets: TaskName
Aliases:
Accepted values: Once, Minute, Hourly, Daily, Weekly, Monthly

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: TaskID
Aliases:
Accepted values: Once, Minute, Hourly, Daily, Weekly, Monthly

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RepeatEvery
How often to repeat

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

### -StartDate
When to start the schedule from

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeZone
The TimeZone to be used for the schedule

```yaml
Type: Object
Parameter Sets: (All)
Aliases:
Accepted values: Pacific/Honolulu, America/Anchorage, America/Los_Angeles, America/Denver, America/Mazatlan, America/Phoenix, America/Belize, America/Chicago, America/Mexico_City, America/Regina, America/Bogota, America/Indianapolis, America/New_York, America/Caracas, America/Halifax, America/St_Johns, America/Buenos_Aires, America/Godthab, America/Santiago, America/Sao_Paulo, Atlantic/South_Georgia, Atlantic/Azores, Atlantic/Cape_Verde, UTC, Atlantic/Reykjavik, Africa/Casablanca, Europe/Dublin, Europe/Belgrade, Europe/Paris, Europe/Warsaw, Africa/Cairo, Africa/Harare, Asia/Jerusalem, Europe/Athens, Europe/Bucharest, Europe/Helsinki, Africa/Nairobi, Asia/Baghdad, Asia/Kuwait, Europe/Minsk, Europe/Moscow, Asia/Tehran, Asia/Baku, Asia/Muscat, Asia/Kabul, Asia/Karachi, Asia/Yekaterinburg, Asia/Calcutta, Asia/Colombo, Asia/Katmandu, Asia/Almaty, Asia/Dhaka, Asia/Rangoon, Asia/Bangkok, Asia/Krasnoyarsk, Asia/Hong_Kong, Asia/Irkutsk, Asia/Kuala_Lumpur, Asia/Taipei, Australia/Perth, Asia/Seoul, Asia/Tokyo, Asia/Yakutsk, Australia/Adelaide, Australia/Darwin, Asia/Vladivostok, Australia/Brisbane, Australia/Hobart, Australia/Sydney, Pacific/Guam, Pacific/Noumea, Pacific/Auckland, Pacific/Fiji, Pacific/Apia, Pacific/Tongatapu

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -expirationDate
When should the schedule stop

```yaml
Type: DateTime
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
