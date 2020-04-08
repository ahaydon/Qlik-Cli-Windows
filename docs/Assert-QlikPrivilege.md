---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version:
schema: 2.0.0
---

# Assert-QlikPrivilege

## SYNOPSIS
Checks if the user has the specified privileges on the resource and throws an exception if not.

## SYNTAX

```
Assert-QlikPrivilege [-InputObject] <Object> [[-privileges] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
This command verifies that the authenticated user has the specified privileges on the target resource.
If the user does not have all of the specified privileges for the resource, Assert-QlikPrivilege will throw an exception.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-QlikApp -filter "stream.name eq 'Everyone'" | Assert-QlikPrivilege -privileges read
```

This command checks that the user has the read privilege on all apps in the Everyone stream.

## PARAMETERS

### -InputObject
Target resource to which privileges are being asserted.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -privileges
List of privileges to assert.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
