function Add-QlikTrigger {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [alias("id")]
    [string]$taskId,
    [string]$name,
    [string[]]$OnSuccess,
    [string]$date
  )

  PROCESS {
    If( $tags ) {
      $tagArray = @(
        $tags | foreach {
          $p = Get-QlikTag -filter "name eq '$_'"
          @{
            id = $p.id
          }
        }
      )
    } else {
      $tagArray = @();
    }

    $task = Get-QlikReloadTask -id $taskId -raw

    If($date) {
      $date = Get-Date -Format yyyy-MM-ddTHH:mm:ss.000Z $date
      if(!$name){$name = 'Scheduled'}
      $update = @{
        schemaEvents = @(@{
          name = $name;
          enabled = $true;
          eventType = 0;
          startDate = "$date";
          expirationDate = "9999-12-30T23:59:59.999Z";
          schemaFilterDescription = @("* * - * * * * *");
          incrementDescription = "0 0 1 0";
          incrementOption = "2";
          reloadTask = @{
            id = $task.id
          }
        })
      }
    } else {
      if(!$name){$name = 'OnSuccess'}
      $update = @{
        compositeEvents = @(
          @{
            name=$name;
            enabled=$true;
            eventType=1;
            reloadTask = @{
              id = $task.id
            }
            timeConstraint=@{
      			  seconds = 0;
      			  minutes = 360;
      			  hours = 0;
      			  days = 0;
            };
            compositeRules=@($OnSuccess | foreach {
              @{
                ruleState=1;

                reloadTask=@{
                  id=$_
                }
              }
            });
            privileges=@("read","update","create","delete")
          }
        )
      }
    }

    $json = $update | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost "/qrs/reloadtask/update" $json
  }
}

function Get-QlikReloadTask {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$Id,
    [string]$Filter,
    [switch]$Full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/reloadtask"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet -Path $path -Filter $filter
  }
}

function Get-QlikTask {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/task"
    If( !$raw ) {
      If( $id ) { $path += "/$id" }
      $path += "/full"
      $result = Invoke-QlikGet $path $filter
      If( !$full ) {
        $result = $result | foreach {
          $props = @{
            name = $_.name
            status = $_ | select -ExpandProperty operational | select -ExpandProperty lastExecutionResult | select -ExpandProperty status
            lastExecution = $_ | select -ExpandProperty operational | select -ExpandProperty lastExecutionResult | select -ExpandProperty startTime
            nextExecution = $_ | select -ExpandProperty operational | select -ExpandProperty nextExecution
          }
          New-Object -TypeName PSObject -Prop $props
        }
      }
      return $result
    } else {
      If( $id ) { $path += "/$id" }
      If( $full ) { $path += "/full" }
      If( $raw ) { $rawOutput = $true }
      return Invoke-QlikGet $path $filter
    }
  }
}

function New-QlikTask {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [alias("id")]
    [string]$appId,
    [parameter(Mandatory=$true,Position=1)]
    [string]$name,
    [string[]]$tags
  )

  PROCESS {
    If( $tags ) {
      $tagArray = @(
        $tags | foreach {
          $p = Get-QlikTag -filter "name eq '$_'" -raw
          @{
            id = $p.id
          }
        }
      )
    } else {
      $tagArray = @();
    }

    $task = @{
      task = @{
        name = $name;
        taskType = 0;
        enabled = $true;
        taskSessionTimeout = 1440;
        maxRetries = 0;
        tags = $tagArray;
        app = @{
          id = $appId
        };
        isManuallyTriggered = $false;
        customProperties = @()
      };
    }

    $json = $task | ConvertTo-Json -Compress -Depth 10

    return Invoke-QlikPost '/qrs/reloadtask/create' $json
  }
}

function Remove-QlikTask {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
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
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    [switch]$wait
  )

  PROCESS {
    $path = "/qrs/task"
    If( $wait ) { $sync = "/synchronous" }
    If( $id -match($script:guid) ) {
      return Invoke-QlikPost "/qrs/task/$id/start$sync"
    } else {
      return Invoke-QlikPost "/qrs/task/start$($sync)?name=$id"
    }
  }
}

function Update-QlikReloadTask {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,

    [Bool]$Enabled,

    [ValidateRange(1,2147483647)]
    [Int]$TaskSessionTimeout,

    [ValidateRange(0,20)]
    [Int]$MaxRetries,

    [string[]]$Tags
  )

  PROCESS {
    $task = Get-QlikReloadTask -Id $id -raw
    If( $psBoundParameters.ContainsKey("Enabled") ) { $task.enabled = $Enabled }
    If( $psBoundParameters.ContainsKey("TaskSessionTimeout") ) { $task.taskSessionTimeout = $TaskSessionTimeout }
    If( $psBoundParameters.ContainsKey("MaxRetries") ) { $task.maxRetries = $MaxRetries }
    If ($tags)
    {
      $task.tags = @(GetTags $tags)
    }
    $json = $task | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut -Path "/qrs/reloadtask/$id" -Body $json
  }
}

function Wait-QlikExecution {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0,ParameterSetName="Execution")]
    [alias("value")]
    [string]$executionId,

    [parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True,Position=0,ParameterSetName="Task")]
    [alias("id")]
    [string]$taskId
  )

  PROCESS {
    if ($executionId)
    {
      $execution = Invoke-QlikGet "/qrs/executionSession/$executionId"
      $resultId = $execution.executionResult.Id
      $taskName = $execution.reloadTask.name
    }
    else
    {
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
        Write-Progress -Activity $taskName -Status $result.status -CurrentOperation ($result.details | select -Last 1).message

        # Wait for 1 second, in a Production setting this should be set much higher to avoid stressing the QRS API
        Start-Sleep -Seconds 1

    } until ($taskstatuscode -gt 3) #status code of more than 3 is a completion (both success and fail)
    return $result
  }
}
