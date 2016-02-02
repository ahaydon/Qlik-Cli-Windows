enum Ensure
{
  Absent
  Present
}

[DscResource()]
class QlikConnect{

  [DscProperty(Key)]
  [string]$Username
  
  [DscProperty()]
  [string]$Computername

  [void] Set()
  {
    $params = @{ Username=$this.Username }
    if( $this.Computername ) { $params.Add( "Computername", $this.Computername ) }
    Connect-Qlik @params -TrustAllCerts
  }
  
  [bool] Test()
  {
    return $false
  }
  
  [QlikConnect] Get()
  {
    $this.Username = $env:Username
    $this.Computername = $env:Computername
    
    return $this
  }
}

[DscResource()]
class QlikCustomProperty{

  [DscProperty(Key)]
  [string]$Name
    
  [DscProperty(Mandatory)]
  [Ensure]$Ensure

  [DscProperty()]
  [string]$ValueType
    
  [DscProperty()]
  [string[]]$ChoiceValues
  
  [DscProperty()]
  [string[]]$ObjectTypes
  
  [void] Set()
  {        
    $item = Get-QlikCustomProperty -full -filter "name eq '$($this.name)'"
    $present = $item -ne $null
    if($this.ensure -eq [Ensure]::Present)
    {
      $params = @{ "Name" = $this.Name }
      if($this.ValueType) { $params.Add("ValueType", $this.ValueType) }
      if($this.ChoiceValues) { $params.Add("ChoiceValues", $this.ChoiceValues) }
      if($this.ObjectTypes) { $params.Add("ObjectTypes", $this.ObjectTypes) }

      if($present)
      {
        if(-not $this.hasProperties($item))
        {
          Update-QlikCustomProperty -id $item.id @params
        }
      } else {
        New-QlikCustomProperty @params
      }
    }
    else
    {
      if($present)
      {
        Write-Verbose -Message "Deleting the property $($this.name)"
        #Remove-QlikCustomProperty -Name $this.Name
      }
    }
  }

  [bool] Test()
  {
    $item = Get-QlikCustomProperty -full -filter "name eq '$($this.name)'"
    $present = $item -ne $null

    if($this.Ensure -eq [Ensure]::Present)
    {
      if($present) {
        if($this.hasProperties($item))
        {
          return $true
        } else {
          return $false
        }
      } else {
        return $false
      }
    }
    else
    {
      return -not $present
    }
  }
  
  [QlikCustomProperty] Get()
  {
    $item = Get-QlikCustomProperty -full -filter "name eq '$($this.name)'"
    $present = $item -ne $null
    
    if ($present)
    {
      $this.ValueType = $item.ValueType
      $this.ChoiceValues = $item.ChoiceValues
      $this.ObjectTypes = $item.ObjectTypes
      $this.Ensure = [Ensure]::Present
    }
    else
    {
      $this.Ensure = [Ensure]::Absent
    }        

    return $this
  }
  
  [bool] hasProperties($item)
  {
    if( !(CompareProperties $this $item @( 'ValueType' ) ) ) 
    {
      return $false
    }

    if($this.ChoiceValues) {
      if(@($this.ChoiceValues).Count -ne @($item.choiceValues).Count) {
        Write-Verbose "Test-HasProperties: ChoiceValues property count - $(@($item.choiceValues).Count) does not match desired state - $(@($this.ChoiceValues).Count)"
        return $false
      } else {
        foreach($value in $item.ChoiceValues) {
          if($this.choiceValues -notcontains $value) {
            Write-Verbose "Test-HasProperties: ChoiceValues property value - $($value) not found in desired state"
            return $false
          }
        }
      }
    }
    
    if($this.ObjectTypes) {
      if(@($this.ObjectTypes).Count -ne @($item.ObjectTypes).Count) {
        Write-Verbose "Test-HasProperties: ObjectTypes property count - $(@($item.ObjectTypes).Count) does not match desired state - $(@($this.ObjectTypes).Count)"
        return $false
      } else {
        foreach($value in $item.ObjectTypes) {
          if($this.ObjectTypes -notcontains $value) {
            Write-Verbose "Test-HasProperties: ObjectTypes property value - $($value) not found in desired state"
            return $false
          }
        }
      }
    }
    
    return $true
  }
}

[DscResource()]
class QlikDataConnection{

  [DscProperty(Key)]
  [string]$Name
    
  [DscProperty(Mandatory)]
  [Ensure]$Ensure

  [DscProperty(Mandatory)]
  [string]$ConnectionString
    
  [DscProperty(Mandatory)]
  [string]$Type
  
  [void] Set()
  {        
    $item = Get-QlikDataConnection -filter "name eq '$($this.name)'"
    $present = $item -ne $null
    if($this.ensure -eq [Ensure]::Present)
    {
      if($present)
      {
        if(-not $this.hasProperties($item))
        {
          Update-QlikDataConnection -id $item.id -ConnectionString $this.ConnectionString
        }
      } else {
        New-QlikDataConnection -Name $this.Name -ConnectionString $this.ConnectionString -Type $this.Type
      }
    }
    else
    {
      if($present)
      {
        Write-Verbose -Message "Deleting the file $($this.name)"
        #Remove-QlikDataConnection -Name $this.Name
      }
    }
  }

  [bool] Test()
  {
    $item = Get-QlikDataConnection -filter "name eq '$($this.name)'"
    $present = $item -ne $null

    if($this.Ensure -eq [Ensure]::Present)
    {
      if($present) {
        if($this.hasProperties($item))
        {
          return $true
        } else {
          return $false
        }
      } else {
        return $false
      }
    }
    else
    {
      return -not $present
    }
  }
  
  [QlikDataConnection] Get()
  {
    $present = $(Get-QlikDataConnection -filter "name eq '$($this.name)'") -ne $null
    
    if ($present)
    {
      $qdc = Get-QlikDataConnection -filter "name eq '$this.name'"
      $this.ConnectionString = $qdc.ConnectionString
      $this.Type = $qdc.Type
      $this.Ensure = [Ensure]::Present
    }
    else
    {
      $this.CreationTime = $null
      $this.Ensure = [Ensure]::Absent
    }        

    return $this
  }
  
  [bool] hasProperties($item)
  {
    if( !(CompareProperties $this $item @( 'ConnectionString', 'Type' ) ) ) 
    {
      return $false
    }
    
    return $true
  }
}

[DscResource()]
class QlikLicense{

  [DscProperty(Key)]
  [string]$Serial
    
  [DscProperty(Mandatory)]
  [string]$Control

  [DscProperty(Mandatory)]
  [string]$Name
    
  [DscProperty(Mandatory)]
  [string]$Organization
  
  [DscProperty(Mandatory)]
  [string]$Lef

  [DscProperty(Mandatory)]
  [Ensure]$Ensure

  [void] Set()
  {        
    $present = $(Get-QlikLicense) -ne "null"
    Write-Debug $present
    if($this.ensure -eq [Ensure]::Present)
    {
      if(-not $present)
      {
        Set-QlikLicense -Serial $this.Serial -Control $this.Control -Name $this.Name -Organization $this.Organization -Lef $this.Lef
      }
    }
    else
    {
      if($present)
      {
        Write-Verbose -Message "Deleting license $($this.Serial)"
        #Remove-QlikLicense
      }
    }
  }

  [bool] Test()
  {
    $present = $(Get-QlikLicense) -ne "null"
    Write-Debug $present
    if($this.Ensure -eq [Ensure]::Present)
    {
      return $present
    }
    else
    {
      return -not $present
    }
  }
  
  [QlikLicense] Get()
  {
    $present = $(Get-QlikLicense) -ne $null
    if ($present)
    {
      $license = Get-QlikLicense
      $this.Serial = $license.Serial
      $this.Name = $license.Name
      $this.Organization = $license.Organization
      $this.Lef = $license.Lef
      $this.Ensure = [Ensure]::Present
    }
    else
    {
      $this.Ensure = [Ensure]::Absent
    }        

    return $this
  }
}

[DscResource()]
class QlikNode{

  [DscProperty(Key)]
  [string]$HostName
    
  [DscProperty()]
  [string]$Name
    
  [DscProperty()]
  [string]$NodePurpose

  [DscProperty()]
  [string[]]$CustomProperties

  [DscProperty()]
  [string[]]$Tags

  [DscProperty()]
  [bool]$Engine

  [DscProperty()]
  [bool]$Proxy

  [DscProperty()]
  [bool]$Scheduler

  [DscProperty()]
  [bool]$Printing

  [DscProperty(Mandatory)]
  [Ensure]$Ensure

  [void] Set()
  {        
    $item = Get-QlikNode -full -filter "hostName eq '$($this.HostName)'"
    $present = $item -ne $null
    
    if($this.ensure -eq [Ensure]::Present)
    {
      Write-Verbose "Proxy should be $($this.Proxy)"
      $params = @{}
      if($this.Name) { $params.Add("Name", $this.Name) }
      if($this.NodePurpose) { $params.Add("NodePurpose", $this.NodePurpose) }
      if($this.CustomProperties) { $params.Add("CustomProperties", $this.CustomProperties) }
      if($this.Tags) { $params.Add("Tags", $this.Tags) }
      if($this.Engine) { $params.Add("engineEnabled", $this.Engine) }
      if($this.Proxy) { $params.Add("proxyEnabled", $this.Proxy) }
      if($this.Scheduler) { $params.Add("schedulerEnabled", $this.Scheduler) }
      if($this.Printing) { $params.Add("printingEnabled", $this.Printing) }
        
      if($present)
      {
        if(-not $this.hasProperties($item))
        {
          Update-QlikNode -id $item.id @params
        }
      }
      else
      {
        Register-QlikNode -hostName $this.HostName @params
      }
    }
    else
    {
      #Remove-QlikNode $this.id
    }
  }

  [bool] Test()
  {
    $item = Get-QlikNode -full -filter "hostName eq '$($this.HostName)'"
    $present = $item -ne $null

    if($present) {
      if($this.hasProperties($item))
      {
        return $true
      } else {
        return $false
      }
    } else {
      return $false
    }
  }
  
  [QlikNode] Get()
  {
    $item = Get-QlikNode -full -filter "hostName eq '$($this.HostName)'"
    $present = $item -ne $null
    
    if ($present)
    {
      $this.NodePurpose = $item.NodePurpose
      $this.CustomProperties = $item.CustomProperties
      $this.Tags = $item.Tags
      $this.Engine = $item.EngineEnabled
      $this.Proxy = $item.ProxyEnabled
      $this.Scheduler = $item.SchedulerEnabled
      $this.Printing = $item.PrintingEnabled
    }
    else
    {
    }        

    return $this
  }
  
  [bool] hasProperties($item)
  {
    if( !(CompareProperties $this $item @( 'NodePurpose', 'Tags' ) ) ) 
    {
      return $false
    }
    
    If($this.CustomProperties) {
      foreach( $defined in $this.CustomProperties) {
        $val = $defined.Split("=")
        $found = $false
        foreach( $exists in $item.customProperties ) {
          if($exists.definition.name -eq $val[0]) {
            if($val[1] -eq "null" -Or $val[1] -ne $exists.value) {
              Write-Verbose "Test-HasProperties: Custom property value - $($val[0])=$($exists.value) does not match desired state - $($val[1])"
              return $false
            } else {
              $found = $true
            }
          }
        }
        if(-not $found) {
          return $false
        }
      }
    }
    
    If($item.EngineEnabled -ne $this.Engine) {
      Write-Verbose "Test-HasProperties: Engine property value - $($item.EngineEnabled) does not match desired state - $($this.Engine)"
      return $false
    }

    If($item.ProxyEnabled -ne $this.Proxy) {
      Write-Verbose "Test-HasProperties: Proxy property value - $($item.ProxyEnabled) does not match desired state - $($this.Proxy)"
      return $false
    }

    If($item.SchedulerEnabled -ne $this.Scheduler) {
      Write-Verbose "Test-HasProperties: Scheduler property value - $($item.SchedulerEnabled) does not match desired state - $($this.Scheduler)"
      return $false
    }

    If($item.PrintingEnabled -ne $this.Printing) {
      Write-Verbose "Test-HasProperties: Printing property value - $($item.PrintingEnabled) does not match desired state - $($this.Printing)"
      return $false
    }

    return $true
  }
}

[DscResource()]
class QlikRule{

  [DscProperty(Key)]
  [string]$Name
    
  [DscProperty(Mandatory)]
  [Ensure]$Ensure

  [DscProperty()]
  [string]$Category

  [DscProperty()]
  [string]$Rule

  [DscProperty()]
  [string]$ResourceFilter

  [DscProperty()]
  [ValidateSet("hub","qmc","both")]
  [string]$RuleContext

  [DscProperty()]
  [int]$Actions

  [DscProperty()]
  [string]$Comment

  [DscProperty()]
  [bool]$Disabled
  
  [void] Set()
  {        
    $item = Get-QlikRule -full -filter "name eq '$($this.Name)'"
    $present = $item -ne $null
    if($this.ensure -eq [Ensure]::Present)
    {
      $params = @{ "Name" = $this.Name }
      if($this.Category) { $params.Add("Category", $this.Category) }
      if($this.Rule) { $params.Add("Rule", $this.Rule) }
      if($this.ResourceFilter) { $params.Add("ResourceFilter", $this.ResourceFilter) }
      if($this.RuleContext) { $params.Add("RuleContext", $this.RuleContext) }
      if($this.Actions) { $params.Add("Actions", $this.Actions) }
      if($this.Comment) { $params.Add("Comment", $this.Comment) }
      if($this.Disabled) { $params.Add("Disabled", $this.Disabled) }
      
      if($present)
      {
        if(-not $this.hasProperties($item))
        {
          Update-QlikRule -id $item.id @params
        }
      } else {
        if($this.Category -eq "license" -And (-not $this.ResourceFilter)) {
          $group = New-QlikUserAccessGroup "License rule to grant user access"
          $params.Add("ResourceFilter", "License.UserAccessGroup_$($group.id)")
        }
        New-QlikRule @params
      }
    }
    else
    {
      if($present)
      {
        Write-Verbose -Message "Deleting the rule $($this.Name)"
        #Remove-QlikRule -Name $this.Name
      }
    }
  }

  [bool] Test()
  {
    $item = Get-QlikRule -full -filter "name eq '$($this.name)'"
    $present = $item -ne $null

    if($this.Ensure -eq [Ensure]::Present)
    {
      if($present) {
        if($this.hasProperties($item))
        {
          return $true
        } else {
          return $false
        }
      } else {
        return $false
      }
    }
    else
    {
      return -not $present
    }
  }
  
  [QlikRule] Get()
  {
    $item = Get-QlikRule -full -filter "name eq '$($this.name)'"
    $present = $item -ne $null
    
    if ($present)
    {
      $this.Category = $item.Category
      $this.Rule = $item.Rule
      $this.ResourceFilter = $item.ResourceFilter
      $this.RuleContext = $item.RuleContext
      $this.Actions = $item.Actions
      $this.Comment = $item.Comment
      $this.Disabled = $item.Disabled
      $this.Ensure = [Ensure]::Present
    }
    else
    {
      $this.Ensure = [Ensure]::Absent
    }        

    return $this
  }
  
  [bool] hasProperties($item)
  {
    if( !(CompareProperties $this $item @( 'Category', 'Rule', 'ResourceFilter', 'Actions', 'Comment', 'Disabled' ) ) )
    {
      return $false
    }

    if($this.RuleContext) {
      $context = -1
      switch ($this.RuleContext)
      {
        both { $context = 0 }
        hub { $context = 1 }
        qmc { $context = 2 }
      }
      If($item.RuleContext -ne $context) {
        Write-Verbose "Test-HasProperties: RuleContext property value - $($item.RuleContext) does not match desired state - $context"
        return $false
      }
    }

    return $true
  }
}

[DscResource()]
class QlikScheduler{

  [DscProperty(Key)]
  [string]$Node
    
  [DscProperty()]
  [string]$SchedulerServiceType
  
  [void] Set()
  {        
    $item = Get-QlikScheduler -full -filter "serverNodeConfiguration.name eq '$($this.Node)'"
    
    $params = @{ "id" = $item.id }
    if($this.SchedulerServiceType) { $params.Add("SchedulerServiceType", $this.SchedulerServiceType) }
    
    Update-QlikScheduler @params
  }

  [bool] Test()
  {
    $item = Get-QlikScheduler -full -filter "serverNodeConfiguration.name eq '$($this.Node)'"

    if($this.hasProperties($item))
    {
      return $true
    } else {
      return $false
    }
  }
  
  [QlikScheduler] Get()
  {
    $item = Get-QlikScheduler -full -filter "serverNodeConfiguration.name eq '$($this.Node)'"
    $present = $item -ne $null
    
    if ($present)
    {
      $this.SchedulerServiceType = $item.settings.SchedulerServiceType
    }

    return $this
  }
  
  [bool] hasProperties($item)
  {
    If($this.SchedulerServiceType) {
      $sched_type = -1
      switch ($this.schedulerServiceType)
      {
        master { $sched_type = 0 }
        slave { $sched_type = 1 }
        both { $sched_type = 2 }
      }
      if($item.settings.SchedulerServiceType -ne $sched_type) {
        Write-Verbose "Test-HasProperties: SchedulerServiceType property value - $($item.settings.SchedulerServiceType) does not match desired state - $($sched_type)"
        return $false
      }
    }
    
    return $true
  }
}

[DscResource()]
class QlikVirtualProxy{

  [DscProperty(Key)]
  [string]$Prefix
    
  [DscProperty(Mandatory)]
  [string]$Description

  [DscProperty(Mandatory)]
  [string]$SessionCookieHeaderName
    
  [DscProperty(Mandatory=$false)]
  [string]$authenticationModuleRedirectUri
  
  [DscProperty(Mandatory=$false)]
  [string]$loadBalancingServerNodes

  [DscProperty(Mandatory=$false)]
  [string[]]$websocketCrossOriginWhiteList

  [DscProperty(Mandatory=$false)]
  [string[]]$proxy

  [DscProperty(Mandatory)]
  [Ensure]$Ensure

  [void] Set()
  {        
    $item = $(Get-QlikVirtualProxy -filter "Prefix eq '$($this.Prefix)'")
    $present = $item -ne $null

    if($this.ensure -eq [Ensure]::Present)
    {
      $engines = Get-QlikNode -filter $this.loadBalancingServerNodes | foreach { $_.id } | ? { $_ }
      $params = @{
        Prefix = $this.Prefix
        Description = $this.Description
        SessionCookieHeaderName = $this.SessionCookieHeaderName
      }
      If( $engines ) { $params.Add("loadBalancingServerNodes", $engines) }
      If( $this.websocketCrossOriginWhiteList ) { $params.Add("websocketCrossOriginWhiteList", $this.websocketCrossOriginWhiteList) }
      If( $this.authenticationModuleRedirectUri ) { $params.Add("authenticationModuleRedirectUri", $this.authenticationModuleRedirectUri) }

      if($present)
      {
        if(-not $this.hasProperties($item))
        {
          Update-QlikVirtualProxy -id $item.id @params
        }
      }
      else
      {
        $item = New-QlikVirtualProxy @params
      }
      
      if( $this.proxy )
      {
        $this.proxy | foreach {
          $qp = Get-QlikProxy -filter "serverNodeConfiguration.hostName eq '$_'"
          Add-QlikProxy $qp.id $item.id
        }
      }
    }
    else
    {
      if($present)
      {
        Write-Verbose -Message "Deleting virtual proxy $($this.Prefix)"
        #Get-QlikVirtualProxy -filter "Prefix eq $($this.Prefix) | Remove-QlikVirtualProxy
      }
    }
  }

  [bool] Test()
  {
    $item = $(Get-QlikVirtualProxy -filter "Prefix eq '$($this.Prefix)'")
    $present = $item -ne $null

    if($this.Ensure -eq [Ensure]::Present)
    {
      if($present) {
        if($this.hasProperties($item))
        {
          return $true
        } else {
          return $false
        }
      } else {
        return $false
      }
    }
    else
    {
      return -not $present
    }
  }
  
  [QlikVirtualProxy] Get()
  {
    $present = $(Get-QlikVirtualProxy -filter "Prefix eq '$($this.Prefix)'") -ne $null
    if ($present)
    {
      $qvp = Get-QlikVirtualProxy -filter "Prefix eq '$($this.Prefix)'"
      $this.Description = $qvp.Description
      $this.SessionCookieHeaderName = $qvp.SessionCookieHeaderName
      $this.authenticationModuleRedirectUri = $qvp.authenticationModuleRedirectUri
      $this.loadBalancingServerNodes = $qvp.loadBalancingServerNodes
      $this.websocketCrossOriginWhiteList = $qvp.websocketCrossOriginWhiteList
      $this.Ensure = [Ensure]::Present
    }
    else
    {
      $this.Ensure = [Ensure]::Absent
    }        

    return $this
  }
  
  [bool] hasProperties($item)
  {
    if( !(CompareProperties $this $item @( 'Description', 'SessionCookieHeaderName', 'authenticationModuleRedirectUri' ) ) )
    {
      return $false
    }
    
    if($this.loadBalancingServerNodes) {
      $nodes = Get-QlikNode -filter $this.loadBalancingServerNodes | foreach { $_.id } | ? { $_ }
      if(@($nodes).Count -ne @($item.loadBalancingServerNodes).Count) {
        Write-Verbose "Test-HasProperties: loadBalancingServerNodes property count - $(@($item.loadBalancingServerNodes).Count) does not match desired state - $(@($this.loadBalancingServerNodes).Count)"
        return $false
      } else {
        foreach($value in $item.loadBalancingServerNodes) {
          if($nodes -notcontains $value.id) {
            Write-Verbose "Test-HasProperties: loadBalancingServerNodes property value - $($value) not found in desired state"
            return $false
          }
        }
      }
    }

    if($this.websocketCrossOriginWhiteList) {
      if(@($this.websocketCrossOriginWhiteList).Count -ne @($item.websocketCrossOriginWhiteList).Count) {
        Write-Verbose "Test-HasProperties: websocketCrossOriginWhiteList property count - $(@($item.websocketCrossOriginWhiteList).Count) does not match desired state - $(@($this.websocketCrossOriginWhiteList).Count)"
        return $false
      } else {
        foreach($value in $item.websocketCrossOriginWhiteList) {
          if($this.websocketCrossOriginWhiteList -notcontains $value) {
            Write-Verbose "Test-HasProperties: websocketCrossOriginWhiteList property value - $($value) not found in desired state"
            return $false
          }
        }
      }
    }
    
    if( $this.proxy ) {
      $proxies = Get-QlikProxy -full -filter "settings.virtualProxies.id eq $($item.id)" | select -ExpandProperty serverNodeConfiguration | select hostName
      foreach( $proxy in $this.proxy )
      {
        if( -Not ($proxies -Contains $proxy) )
        {
          Write-Verbose "Test-HasProperties: $proxy not linked"
          return $false
        }
      }
    }

    return $true
  }
}

function CompareProperties( $expected, $actual, $prop )
{
  $result = $true
  
  $prop.foreach({
    If($expected.$_ -And ($actual.$_ -ne $expected.$_)) {
      Write-Verbose "CompareProperties: $_ property value - $($actual.$_) does not match desired state - $($expected.$_)"
      $result = $false
    }
  })

  return $result
}

