---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version:
schema: 2.0.0
---

# New-QlikLicenseRule

## SYNOPSIS
Creates a new license allocation rule.

## SYNTAX

```
New-QlikLicenseRule [[-Name] <String>] [-Type] <String> [[-Rule] <String>] [[-Comment] <String>] [-Disabled]
 [[-CustomProperties] <String[]>] [[-Tags] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Creates both the License Access Group required for the License Rule to operate correctly

## EXAMPLES

### Example 1
```powershell
PS C:\>  New-QlikLicenseRule -Name "Test" -Type Professional -Rule "(user.group like `"Qlik_Professional`")" -Comment "Assign users in the Qlik_Professional Group a Professional License"
```

Will create a License allocation rule to assign users in the Group Qlik_Professional a Professional License

### Example 2
```powershell
PS C:\> New-QlikLicenseRule -Name "Test2" -Type Analyzer -Rule "(!(user.group like `"Qlik_Professional`"))" -Comment "Assign users NOT in the Qlik_Professional Group a Analyzer License"
```

Will create a License allocation rule to assign users Not in the Group Qlik_Professional a Analyzer License

## PARAMETERS

### -Comment
The description of the rule

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomProperties
Any custom properties to be added to the Rule

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Disabled
If the Rule is to be disabled

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

### -Name
The name of the rule

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

### -Rule
the conditions for the rule 

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tags
Tag to be added to the rule

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
If the Rule is related to a Analyzer or Professional license

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Analyzer, Professional

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

[Professional access rules](https://help.qlik.com/en-US/sense/csh/Subsystems/DeployAdministerQSE/Content/Sense_DeployAdminister/QSEoW/Administer_QSEoW/Managing_QSEoW/professional-access-rules.htm)
 
[Analyzer access rules](https://help.qlik.com/en-US/sense/csh/Subsystems/DeployAdministerQSE/Content/Sense_DeployAdminister/QSEoW/Administer_QSEoW/Managing_QSEoW/analyzer-access-rules.htm)