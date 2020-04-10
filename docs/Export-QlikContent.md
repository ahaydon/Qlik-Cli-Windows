---
external help file: Qlik-Cli-help.xml
Module Name: Qlik-Cli
online version:
schema: 2.0.0
---

# Export-QlikContent

## SYNOPSIS
Downloads the content of an app or library.

## SYNTAX

### App
```
Export-QlikContent -AppID <String> [-SourceFile <String>] -OutPath <DirectoryInfo> [<CommonParameters>]
```

### Library
```
Export-QlikContent -LibraryName <String> [-SourceFile <String>] -OutPath <DirectoryInfo> [<CommonParameters>]
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

### -AppID
{{ Fill AppID Description }}

```yaml
Type: String
Parameter Sets: App
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LibraryName
{{ Fill LibraryName Description }}

```yaml
Type: String
Parameter Sets: Library
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutPath
{{ Fill OutPath Description }}

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceFile
{{ Fill SourceFile Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
