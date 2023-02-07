function Add-QlikTrigger {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [alias("id")]
        [string]$taskId,
        [string]$name,

        [parameter(ParameterSetName = "CompositeEvent")]
        [string[]]$OnSuccess,

        [parameter(ParameterSetName = "SchemaEvent")]
        [DateTime]$startDate,
        [parameter(ParameterSetName = "SchemaEvent")]
        [DateTime]$expirationDate,
        [parameter(ParameterSetName = "SchemaEvent")]
        [string]$timeZone,
        [parameter(ParameterSetName = "SchemaEvent")]
        [bool]$daylightSavingTime
    )

    PROCESS {
        # $task = Get-QlikReloadTask -id $taskId -raw

        If ($startDate) {
            # $date = Get-Date -Format yyyy-MM-ddTHH:mm:ss.000Z $date
            if (!$name) { $name = 'Scheduled' }
            $update = @{
                schemaEvents = @(@{
                        name = $name;
                        enabled = $true;
                        eventType = 0;
                        startDate = $startDate.ToString("yyyy-MM-ddTHH:mm:ss.000Z");
                        expirationDate = if ($expirationDate) { $expirationDate.ToString("yyyy-MM-ddTHH:mm:ss.000Z") } else { "9999-12-30T23:59:59.999Z" };
                        schemaFilterDescription = @("* * - * * * * *");
                        incrementDescription = "0 0 1 0";
                        incrementOption = "2";
                        reloadTask = @{
                            id = $taskId
                        }
                    })
            }
        }
        else {
            if (!$name) { $name = 'OnSuccess' }
            $update = @{
                compositeEvents = @(
                    @{
                        name = $name;
                        enabled = $true;
                        eventType = 1;
                        reloadTask = @{
                            id = $taskId
                        }
                        timeConstraint = @{
                            seconds = 0;
                            minutes = 360;
                            hours = 0;
                            days = 0;
                        };
                        compositeRules = @($OnSuccess | ForEach-Object {
                                @{
                                    ruleState = 1;

                                    reloadTask = @{
                                        id = $_
                                    }
                                }
                            });
                        privileges = @("read", "update", "create", "delete")
                    }
                )
            }
        }

        if ($expirationDate) { $update.expirationDate = $expirationDate }
        if ($timeZone) { $update.timeZone = $timeZone }
        if ($daylightSavingTime) { $update.daylightSavingTime = $daylightSavingTime }

        $json = $update | ConvertTo-Json -Compress -Depth 10

        return Invoke-QlikPost "/qrs/reloadtask/update" $json
    }
}

function Get-QlikReloadTask {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$Filter,
        [switch]$Full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/reloadtask"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet -path $path -filter $filter
    }
}

function Get-QlikTask {
    [CmdletBinding()]
    param (
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/task"
        If ( !$raw ) {
            $path += "/full"
            $result = Invoke-QlikGet -path $path -filter $filter
            If ( !$full ) {
                $result = $result | ForEach-Object {
                    $props = @{
                        name = $_.name
                        status = $_ | Select-Object -ExpandProperty operational | Select-Object -ExpandProperty lastExecutionResult | Select-Object -ExpandProperty status
                        lastExecution = $_ | Select-Object -ExpandProperty operational | Select-Object -ExpandProperty lastExecutionResult | Select-Object -ExpandProperty startTime
                        nextExecution = $_ | Select-Object -ExpandProperty operational | Select-Object -ExpandProperty nextExecution
                    }
                    New-Object -TypeName PSObject -Prop $props
                }
            }
            return $result
        }
        else {
            If ( $full ) { $path += "/full" }
            If ( $raw ) { $rawOutput = $true }
            return Invoke-QlikGet -path $path -filter $filter
        }
    }
}

function New-QlikTask {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [alias("id")]
        [string]$appId,
        [parameter(Mandatory = $true, Position = 1)]
        [string]$name,
        [string[]]$customProperties,
        [string[]]$tags
    )

    PROCESS {
        $task = @{
            task = @{
                name = $name;
                taskType = 0;
                enabled = $true;
                taskSessionTimeout = 1440;
                maxRetries = 0;
                app = @{
                    id = $appId
                };
                isManuallyTriggered = $false;
            };
        }

        if ($PSBoundParameters.ContainsKey("customProperties")) { $task.task.customProperties = @(GetCustomProperties $customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $task.task.tags = @(GetTags $tags) }

        $json = $task | ConvertTo-Json -Compress -Depth 10

        return Invoke-QlikPost '/qrs/reloadtask/create' $json
    }
}

function Remove-QlikTask {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        $taskType = "ReloadTask"
        $json = (@{
                items = @(
                    @{
                        type = $taskType;
                        objectID = $id
                    }
                )
            } | ConvertTo-Json -Compress -Depth 10)
        $selection = Invoke-QlikPost "/qrs/selection" $json
        $result = Invoke-QlikDelete "/qrs/selection/$($selection.Id)/$taskType"
        Invoke-QlikDelete "/qrs/selection/$($selection.Id)" | Out-Null

        return $result
    }
}

function Start-QlikTask {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,
        [switch]$wait
    )

    PROCESS {
        $path = "/qrs/task"
        If ( $wait ) { $sync = "/synchronous" }
        If ( $id -match ($script:guid) ) {
            return Invoke-QlikPost "/qrs/task/$id/start$sync"
        }
        else {
            return Invoke-QlikPost "/qrs/task/start$($sync)?name=$id"
        }
    }
}

function Stop-QlikTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [guid]$id
    )

    PROCESS {
        return Invoke-QlikPost "/qrs/task/$id/stop"
    }
}

function Update-QlikReloadTask {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,

        [Bool]$Enabled,

        [ValidateRange(1, 2147483647)]
        [Int]$TaskSessionTimeout,

        [ValidateRange(0, 20)]
        [Int]$MaxRetries,

        [object[]]$customProperties,
        [object[]]$tags
    )

    PROCESS {
        $task = Get-QlikReloadTask -Id $id -raw
        If ( $psBoundParameters.ContainsKey("Enabled") ) { $task.enabled = $Enabled }
        If ( $psBoundParameters.ContainsKey("TaskSessionTimeout") ) { $task.taskSessionTimeout = $TaskSessionTimeout }
        If ( $psBoundParameters.ContainsKey("MaxRetries") ) { $task.maxRetries = $MaxRetries }
        if ($PSBoundParameters.ContainsKey("customProperties")) { $task.customProperties = @(GetCustomProperties $customProperties $task.customProperties) }
        if ($PSBoundParameters.ContainsKey("tags")) { $task.tags = @(GetTags $tags $task.tags) }

        $json = $task | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut -path "/qrs/reloadtask/$id" -body $json
    }
}

function Wait-QlikExecution {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0, ParameterSetName = "Execution")]
        [alias("value")]
        [string]$executionId,

        [parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $True, Position = 0, ParameterSetName = "Task")]
        [alias("id")]
        [string]$taskId
    )

    PROCESS {
        if ($executionId) {
            $execution = Invoke-QlikGet "/qrs/executionSession/$executionId"
            $resultId = $execution.executionResult.Id
            $taskName = $execution.reloadTask.name
        }
        else {
            $task = Invoke-QlikGet "/qrs/reloadTask/$taskId"
            $resultId = $task.operational.lastExecutionResult.id
            $taskName = $task.name
        }
        do {
            # Get task status
            $rawOutput = $true
            $result = Invoke-QlikGet "/qrs/executionResult/$resultId"

            # Get internal task status code
            $taskstatuscode = $result.status

            $result = FormatOutput($result)
            Write-Progress -Activity $taskName -Status $result.status -CurrentOperation ($result.details | Select-Object -Last 1).message

            # Wait for 1 second, in a Production setting this should be set much higher to avoid stressing the QRS API
            Start-Sleep -Seconds 1

        } until ($taskstatuscode -gt 3) #status code of more than 3 is a completion (both success and fail)
        return $result
    }
}


function New-QlikTaskSchedule {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param
    (
        [string]$Name,
        [Parameter(ParameterSetName = 'TaskID')]
        [Parameter(ParameterSetName = 'TaskName', Mandatory = $true)]
        [ValidateSet('Once', 'Minute', 'Hourly', 'Daily', 'Weekly', 'Monthly')]
        [string]$Repeat = 'Daily',
        [int]$RepeatEvery = 1,
        [datetime]$StartDate = $(Get-Date),
        [dateTime]$expirationDate = "9999-01-01T00:00:00.000",
        [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
        [string[]]$DaysOfWeek = "Monday",
        [ValidateRange(1, 31)]
        [string[]]$DaysOfMonth,
        [ValidateSet('Pacific/Honolulu', 'America/Anchorage', 'America/Los_Angeles', 'America/Denver', 'America/Mazatlan', 'America/Phoenix', 'America/Belize', 'America/Chicago', 'America/Mexico_City', 'America/Regina', 'America/Bogota', 'America/Indianapolis', 'America/New_York', 'America/Caracas', 'America/Halifax', 'America/St_Johns', 'America/Buenos_Aires', 'America/Godthab', 'America/Santiago', 'America/Sao_Paulo', 'Atlantic/South_Georgia', 'Atlantic/Azores', 'Atlantic/Cape_Verde', 'UTC', 'Atlantic/Reykjavik', 'Africa/Casablanca', 'Europe/Dublin', 'Europe/Belgrade', 'Europe/Paris', 'Europe/Warsaw', 'Africa/Cairo', 'Africa/Harare', 'Asia/Jerusalem', 'Europe/Athens', 'Europe/Bucharest', 'Europe/Helsinki', 'Africa/Nairobi', 'Asia/Baghdad', 'Asia/Kuwait', 'Europe/Minsk', 'Europe/Moscow', 'Asia/Tehran', 'Asia/Baku', 'Asia/Muscat', 'Asia/Kabul', 'Asia/Karachi', 'Asia/Yekaterinburg', 'Asia/Calcutta', 'Asia/Colombo', 'Asia/Katmandu', 'Asia/Almaty', 'Asia/Dhaka', 'Asia/Rangoon', 'Asia/Bangkok', 'Asia/Krasnoyarsk', 'Asia/Hong_Kong', 'Asia/Irkutsk', 'Asia/Kuala_Lumpur', 'Asia/Taipei', 'Australia/Perth', 'Asia/Seoul', 'Asia/Tokyo', 'Asia/Yakutsk', 'Australia/Adelaide', 'Australia/Darwin', 'Asia/Vladivostok', 'Australia/Brisbane', 'Australia/Hobart', 'Australia/Sydney', 'Pacific/Guam', 'Pacific/Noumea', 'Pacific/Auckland', 'Pacific/Fiji', 'Pacific/Apia', 'Pacific/Tongatapu')]
        $TimeZone = 'UTC',
        [switch]$DaylightSavingTime,
        [Parameter(ParameterSetName = 'TaskID', Mandatory = $true)]
        [string]$ReloadTaskID,
        [Parameter(ParameterSetName = 'TaskName', Mandatory = $true)]
        [string]$ReloadTaskName
    )

    [string]$StartDate = $startDate.ToString("yyyy-MM-ddTHH:mm:ss.000Z");
    [string]$expirationDate = $expirationDate.ToString("yyyy-MM-ddTHH:mm:ss.000Z");

    if ($PSBoundParameters.ContainsKey("DaysOfWeek")) {
        $WeekDays = ($DaysOfWeek | ForEach-Object {
                switch ($_)	{
                    Monday { 1 }
                    Tuesday { 2 }
                    Wednesday { 3 }
                    Thursday { 4 }
                    Friday { 5 }
                    Saturday { 6 }
                    Sunday { 0 }
                    default { }
                }
            }) -join ","
    }

    if ($PSBoundParameters.ContainsKey("DaysOfMonth")) {
        $MonthDays = $DaysOfMonth -join ","
    }
    if ($DaylightSavingTime.IsPresent -eq $true) {
        $DST = 0
    }
    else {
        $DST = 1
    }

    Switch ($Repeat) {
        Once {
            $incrementDescription = "0 0 0 0"
            $schemaFilterDescription = "* * - * * * * *"
        }
        Minute {
            $incrementDescription = "$RepeatEvery 0 0 0"
            $schemaFilterDescription = "* * - * * * * *"
        }
        Hourly {
            $incrementDescription = "0 $RepeatEvery 0 0"
            $schemaFilterDescription = "* * - * * * * *"
        }
        Daily {
            $incrementDescription = "0 0 $RepeatEvery 0"
            $schemaFilterDescription = "* * - * * * * *"
        }
        Weekly {
            $incrementDescription = "0 0 1 0"
            $schemaFilterDescription = "* * - $WeekDays $RepeatEvery * * *"
        }
        Monthly {
            $incrementDescription = "0 0 1 0"
            $schemaFilterDescription = "* * - * * $MonthDays * *"
        }
    }

    if ($PSBoundParameters.ContainsKey("Name") -eq $false) {
        $name = "$repeat"
    }

    if ($PSCmdlet.ParameterSetName -eq "TaskID") {
        $filter = "id eq $ReloadTaskID"
    }
    if ($PSCmdlet.ParameterSetName -eq "TaskName") {
        $filter = "name eq '$ReloadTaskName'"
    }

    try {
        $reloadtask = Invoke-QlikGet "/qrs/task" -filter $filter
        if ($Null -eq $reloadtask) {
            throw
        }
    }
    catch {
        Write-Error -Message "Could not find Specified Reload Task"
        break
    }

    $TaskEvent = [pscustomobject] @{
        name = "$($Name)"
        timezone = "$($timezone)"
        daylightSavingTime = $DST
        startDate = $StartDate
        expirationDate = $expirationDate
        schemaFilterDescription = @($schemaFilterDescription)
        incrementDescription = $incrementDescription
        incrementOption = 1
        Integer = $null
        reloadTask = ""
        userSyncTask = ""
        externalProgramTask = ""
    }
    switch ($reloadtask.taskType) {
        0 {
            $TaskEvent.reloadTask = $reloadtask
        }
        1 {
            $TaskEvent.externalProgramTask = $reloadtask
        }
    }

    try	{
        $json = $TaskEvent | ConvertTo-Json -Compress -Depth 10 -Verbose
        $QSevent = Invoke-QlikPost /qrs/schemaevent $json
    }
    catch {
        Write-Error -Message "Unable to create Reload Task event"
        break
    }

    return $QSevent
}

Function Remove-QlikTaskSchedule {
    param
    (
        [Parameter(Mandatory = $true)]
        [guid]$ID
    )
    Invoke-QlikDelete "/qrs/schemaevent/$ID"
}


Function Get-QlikTaskSchedule {

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param
    (
        [string]$Name,
        [Parameter(ParameterSetName = 'TaskID',
            Mandatory = $true)]
        [string]$ReloadTaskID,
        [Parameter(ParameterSetName = 'TaskName',
            Mandatory = $true)]
        [string]$ReloadTaskName,
        [switch]$Full
    )

    if ($PSCmdlet.ParameterSetName -eq "TaskID") {
        $filter = "id eq $ReloadTaskID"
    }
    if ($PSCmdlet.ParameterSetName -eq "TaskName") {
        $filter = "name eq '$ReloadTaskName'"
    }
    if ($PSCmdlet.ParameterSetName -ne "Default") {
        try {
            $reloadtasks = Invoke-QlikGet "/qrs/task" -filter $filter
            if ($Null -eq $reloadtasks) {
                throw
            }
        }
        catch {
            Write-Error -Message "Could not find Specified Reload Task"
            break
        }

        $schemaeventfilters = foreach ($reloadtask in $reloadtasks) {
            switch ($reloadtask.taskType) {
                0 {
                    "reloadTask.id eq $($reloadtask.id)"
                }
                1 {
                    "externalProgramTask.id eq $($reloadtask.id)"
                }
            }
        }
        $schemaeventfilter = $schemaeventfilters -join " or "
    }

    if ($Name.Length -gt 0) {
        if ($Name.Contains('*')) {

            [string[]]$NameParts = $Name.Split('*') | Where-Object {
                $_.Length -gt 0
            }

            if ($NameParts.Count -gt 1) {
                if (!($Name.StartsWith('*'))) {
                    $NameParts[0] = "name sw '$($NameParts[0])'"
                }
                else {
                    $NameParts[0] = "name ew '$($NameParts[0])'"
                }

                if (!($Name.EndsWith('*'))) {
                    $NameParts[-1] = "name ew '$($NameParts[-1])'"
                }
                else {
                    $NameParts[-1] = "name so '$($NameParts[-1])'"
                }
                for ([int]$I = 1; $I -lt (($NameParts | Measure-Object).Count - 1); $I++) {
                    $NameParts[$I] = "name so '$($NameParts[$I])'"
                }
            }
            else {
                if (!($Name.StartsWith('*'))) {
                    $NameParts[0] = "name sw '$($NameParts[0])'"
                }
                else {
                    $NameParts[0] = "name ew '$($NameParts[0])'"
                }
            }
            $NameFilter = $NameParts -join " and "
        }
        else {
            $NameFilter = "name eq '$Name'"
        }

        if ($schemaeventfilter.Length -gt 0) {
            $schemaeventfilter = "$schemaeventfilter and $NameFilter"
        }
        else {
            $schemaeventfilter = $NameFilter
        }
    }

    if ($full.IsPresent -eq $true) {
        $schemaeventpath = "/qrs/schemaevent/full"
    }
    else {
        $schemaeventpath = "/qrs/schemaevent"
    }
    Write-Verbose "$schemaeventpath"
    Write-Verbose "$schemaeventfilter"
    Invoke-QlikGet -path $schemaeventpath -filter $schemaeventfilter
}
