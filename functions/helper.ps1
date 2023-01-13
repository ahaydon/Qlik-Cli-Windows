function FormatOutput($objects, $schemaPath) {
    $isDate = "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"

    Write-Debug "Resolving enums"
    If ( !$Script:enums ) {
        $rawOutput = $true
        # If enums haven't been read get them and save them for later use
        $enums = Invoke-QlikGet "/qrs/about/api/enums"
        $Script:enums = $enums | Get-Member -MemberType NoteProperty | ForEach-Object { $enums.$($_.Name) }
    }
    If ( !$Script:relations ) {
        # If relations haven't been read get them and save them for later use
        $Script:relations = Get-QlikRelations
    }
    foreach ( $object in $objects ) {
        # Determine the object type being formatted
        If ( !$schemaPath ) { $schemaPath = $object.schemaPath }
        Write-Debug "Schema path: $schemaPath"
        foreach ( $prop in ( $object | Get-Member -MemberType NoteProperty ) ) {
            If ( $object.$($prop.Name) -is [string] -And $object.$($prop.Name) -match $isDate ) {
                # Update any value that looks like a date to a more human readable format
                $object.$($prop.Name) = Get-Date -Format "yyyy/MM/dd HH:mm" $object.$($prop.Name)
            }
            Write-Debug "Property: $schemaPath.$($prop.Name)"
            # Find enums related to the current object property
            $enumsRelated = $Script:enums | Where-Object { $_.Usages -contains "$schemaPath.$($prop.Name)" }
            If ( $enumsRelated ) {
                # If there is an enum for the property then resolve it
                $value = ((($enumsRelated | Select-Object -ExpandProperty values | Where-Object { $_ -like "$($object.$($prop.Name)):*" }) -split ":")[1]).TrimStart()
                Write-Debug "Resolving $($prop.Name) from $($object.$($prop.Name)) to $value"
                $object.$($prop.Name) = $value
            }
            # Check for relations referenced by the property
            $relatedRelations = $Script:relations -like "$schemaPath.$($prop.Name) > *"
            If ( $relatedRelations ) {
                # If there are relations for the property then call self for the object
                Write-Debug "Traversing $($prop.Name)"
                $object.$($prop.Name) = FormatOutput $object.$($prop.Name) $(($relatedRelations -Split ">")[1].TrimStart())
            }
        }
    }
    return $objects
}

function GetCustomProperties($customProperties, $existing) {
    $prop = @(
        $customProperties | Where-Object { $_ } | ForEach-Object {
            if ($_ -is [ScriptBlock]) {
                $new = $existing | ForEach-Object $_
                GetCustomProperties $new
            }
            elseif ($_ -is [System.Collections.Hashtable]) {
                foreach ($key in $_.Keys) {
                    $p = Get-QlikCustomProperty -filter "name eq '$key'" -raw
                    if (! $p) {
                        Write-Warning "Property with name '$key' not found"
                        continue
                    }
                    @{
                        value = ($p.choiceValues -eq $_.$key)[0]
                        definition = $p
                    }
                }
            }
            elseif ($_ -is [System.Management.Automation.PSCustomObject]) {
                $_
            }
            elseif ($_ -is [System.String]) {
                $val = $_.Split("=", 2)
                $p = Get-QlikCustomProperty -filter "name eq '$($val[0])'" -raw
                if (! $p) {
                    Write-Warning "Property with name '$($val[0])' not found"
                    return
                }
                if ($p.choiceValues -notcontains $val[1]) {
                    Write-Warning "Value '$($val[1])' not valid for property '$($val[0])'"
                    return
                }
                @{
                    value = ($p.choiceValues -eq $val[1])[0]
                    definition = $p
                }
            }
            else {
                Write-Warning "Unrecognised custom property: $_"
            }
        }
    )
    return $prop
}

function GetTags($tags, $existing) {
    $prop = @(
        $tags | Where-Object { $_ } | ForEach-Object {
            if ($_ -match $script:guid) {
                @{ id = $_ }
            }
            elseif ($_ -is [ScriptBlock]) {
                $new = $existing | ForEach-Object $_
                GetTags $new
            }
            elseif ($_ -is [System.Management.Automation.PSCustomObject]) {
                $_
            }
            elseif ($_ -is [System.String]) {
                $p = Get-QlikTag -filter "name eq '$_'"
                if (! $p) {
                    Write-Warning "Tag with name '$_' not found"
                    Continue
                }
                @{
                    id = $p.id
                }
            }
            else {
                Write-Warning "Unrecognised tag: $_"
            }
        }
    )
    return $prop
}

function GetUser($param) {
    if ($param -is [System.String]) {
        if ($param -match $script:guid) {
            return @{ id = $param }
        }
        elseif ($param -match '\w+\\\w+') {
            $parts = $param -split '\\'
            $userDirectory = $parts[0]
            $userId = $parts[1]
        }
        elseif ($param -match '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$') {
            $parts = $param -split '@'
            $userId = $parts[0]
            $userDirectory = $parts[1]
        }
        else {
            throw 'Unrecognised format for user parameter'
        }

        Get-QlikUser -filter "userDirectory eq '$userDirectory' and userId eq '$userId'"
    }
    elseif ($param -is [System.Collections.Hashtable] -or $param -is [System.Management.Automation.PSCustomObject]) {
        return $param
    }
    else {
        throw "Invalid type for user parameter, $($param.GetType().Name)"
    }
}
