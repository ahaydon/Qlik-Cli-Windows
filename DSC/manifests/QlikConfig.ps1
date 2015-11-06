Configuration QlikConfig
{
  Import-DSCResource -ModuleName xNetworking,xSmbShare,QlikResources

  Node $AllNodes.Where{$_.Central -eq $true}.NodeName
  {
    QlikConnect vagrant
    {
      Username = "sense1\vagrant"
      Computername = $AllNodes.Where{$_.Central}.NodeName
    }

    QlikLicense SiteLicense
    {
      Serial = $ConfigurationData.NonNodeData.License.Serial
      Control = $ConfigurationData.NonNodeData.License.Control
      Name = $ConfigurationData.NonNodeData.License.Name
      Organization = $ConfigurationData.NonNodeData.License.Organization
      Lef = $ConfigurationData.NonNodeData.License.Lef
      Ensure = "Present"
      DependsOn = "[QlikConnect]vagrant"
    }
    
    QlikCustomProperty Role
    {
      Name = "Role"
      ChoiceValues = "Proxy", "Engine", "Scheduler"
      ObjectTypes = "ServerNodeConfiguration"
      Ensure = "Present"
      DependsOn = "[QlikLicense]SiteLicense"
    }
    
    QlikCustomProperty Location
    {
      Name = "Location"
      ChoiceValues = $ConfigurationData.NonNodeData.Location
      ObjectTypes = "ServerNodeConfiguration"
      Ensure = "Present"
      DependsOn = "[QlikLicense]SiteLicense"
    }
    
    QlikCustomProperty NodeAffinity
    {
      Name = "NodeAffinity"
      ChoiceValues = @(Get-QlikNode -filter "@Role eq 'engine'" | foreach { $_.hostName })
      ObjectTypes = ("App", "Stream")
      Ensure = "Present"
      DependsOn = "[QlikLicense]SiteLicense"
    }
    
    $AllNodes.foreach(
    {
      if( -not $_.Central -and (Get-QlikNode -filter "hostName eq '$($_.NodeName)'") -ne $null)
      {
        QlikNode $_.NodeName
        {
          HostName     = $_.NodeName
          Ensure       = "Present"
          Proxy        = ($_.Role -eq "Proxy")
          Engine       = ($_.Role -eq "Engine" -Or $_.Role -eq "Scheduler")
          Printing     = ($_.Role -eq "Engine")
          Scheduler    = ($_.Role -eq "Scheduler")
          CustomProperties = 
          @(
            "Role=$($_.Role)",
            "Location=$($_.Location)"
          )
          DependsOn = "[QlikCustomProperty]Role", "[QlikCustomProperty]Location"
        }
      }
    })

    QlikNode $AllNodes.Where{$_.Central}.NodeName
    {
      HostName = $Node.NodeName
      Ensure = "Present"
      CustomProperties = 
      @(
        "Role=$($Node.Role)",
        "Location=$($Node.Location)"
      )
      DependsOn = "[QlikCustomProperty]Role", "[QlikCustomProperty]Location"
    }
    
    QlikDataConnection ServerLogFolder
    {
      Name = "ServerLogFolder"
      ConnectionString = "\\sense1\QlikLog"
      Type = "Folder"
      Ensure = "Present"
      DependsOn = "[xSmbShare]QlikLog", "[QlikLicense]SiteLicense"
    }

    QlikDataConnection ArchivedLogsFolder
    {
      Name = "ArchivedLogsFolder"
      ConnectionString = "\\sense1\QlikArchiveLog"
      Type = "Folder"
      Ensure = "Present"
      DependsOn = "[xSmbShare]QlikArchiveLog", "[QlikLicense]SiteLicense"
    }
    
    QlikRule ResourcesToNonCentralNodes
    {
      Name = "ResourcesToNonCentralNodes"
      Disabled = $true
      Ensure = "Present"
      DependsOn = "[QlikDataConnection]ServerLogFolder", "[QlikDataConnection]ArchivedLogsFolder"
    }
    
    QlikRule ResourcesToSchedulers
    {
      Name = "ResourcesToSchedulers"
      Category = "sync"
      Rule = '((node.@Role="Scheduler"))'
      ResourceFilter = "App_*"
      Ensure = "Present"
      DependsOn = "[QlikCustomProperty]Role"
    }

    QlikRule ResourceNodeAffinity
    {
      Name = "ResourceNodeAffinity"
      Category = "sync"
      Actions = 1
      Rule = '((resource.@NodeAffinity=node.name or resource.stream.@NodeAffinity=node.name) or (resource.@NodeAffinity.Empty() and resource.stream.@NodeAffinity.Empty()))'
      ResourceFilter = "App_*"
      Ensure = "Present"
      DependsOn = "[QlikCustomProperty]NodeAffinity"
    }

    QlikRule RootAccess
    {
      Name = "License rule to grant RootAdmin access"
      Rule = '((user.roles="RootAdmin"))'
      Category = "license"
      Actions = 1
      Comment = "Rule to setup automatic user access"
      RuleContext = "hub"
      Ensure = "Present"
      DependsOn = "[QlikLicense]SiteLicense"
    }

    if( (Get-QlikNode -filter "schedulerEnabled eq true" -count).value -gt 1 -And (Get-QlikNode -filter "isCentral eq true and @role eq scheduler") -eq $null ) {
      QlikScheduler Central
      {
        Node = "Central"
        SchedulerServiceType = "Master"
        DependsOn = "[QlikDataConnection]ServerLogFolder", "[QlikDataConnection]ArchivedLogsFolder"
      }
    } else {
      QlikScheduler Central
      {
        Node = "Central"
        SchedulerServiceType = "Both"
      }
    }
    
    $ConfigurationData.NonNodeData.Location.foreach({
      QlikVirtualProxy "$_ Proxy"
      {
        Prefix = "$_"
        Description = "$_ Proxy"
        SessionCookieHeaderName = "X-Qlik-Session-$_"
        Ensure = "Present"
        loadBalancingServerNodes = "@location eq $_ and @role eq engine"
        DependsOn = "[QlikLicense]SiteLicense"
      }
    })
    
    xSmbShare QlikLog
    { 
      Ensure = "Present"  
      Name   = "QlikLog" 
      Path = "C:\ProgramData\Qlik\Sense\Log"   
      FullAccess = "Administrators"
      Description = "Qlik Sense Scheduler access to central logs" 
    } 
    
    xSmbShare QlikArchiveLog
    { 
      Ensure = "Present"  
      Name   = "QlikArchiveLog" 
      Path = "C:\ProgramData\Qlik\Sense\Repository\Archived Logs"   
      FullAccess = "Administrators"
      Description = "Qlik Sense Scheduler access to archived logs" 
    } 
  }
  
  Node $AllNodes.NodeName
  {
    xFirewall QRS-Sync
    {
      Name                  = "QRS-Sync"
      DisplayName           = "Qlik Sense Repository Replication"
      DisplayGroup          = "Qlik Sense"
      Ensure                = "Present"
      Action                = "Allow"
      Enabled               = "True"
      Profile               = ("Domain", "Private", "Public")
      Direction             = "InBound"
      LocalPort             = ("4241")         
      Protocol              = "TCP"
    }
    
    xFirewall QRS-ws
    {
      Name                  = "QRS-WebSocket"
      DisplayName           = "Qlik Sense Repository Service (WebSocket)"
      DisplayGroup          = "Qlik Sense"
      Ensure                = "Present"
      Action                = "Allow"
      Enabled               = "True"
      Profile               = ("Domain", "Private", "Public")
      Direction             = "InBound"
      LocalPort             = ("4239")         
      Protocol              = "TCP"
    }
    
    xFirewall QRS-rest
    {
      Name                  = "QRS"
      DisplayName           = "Qlik Sense Repository Service (REST)"
      DisplayGroup          = "Qlik Sense"
      Ensure                = "Present"
      Action                = "Allow"
      Enabled               = "True"
      Profile               = ("Domain", "Private", "Public")
      Direction             = "InBound"
      LocalPort             = ("4242")         
      Protocol              = "TCP"
    }
    
    xFirewall QSS-Master
    {
      Name                  = "QSS-Master"
      DisplayName           = "Qlik Sense Scheduler Master"
      DisplayGroup          = "Qlik Sense"
      Ensure                = "Present"
      Action                = "Allow"
      Enabled               = "True"
      Profile               = ("Domain", "Private", "Public")
      Direction             = "InBound"
      LocalPort             = ("5050")         
      Protocol              = "TCP"
    }
    
    xFirewall QSS-Slave
    {
      Name                  = "QSS-Slave"
      DisplayName           = "Qlik Sense Scheduler Slave"
      DisplayGroup          = "Qlik Sense"
      Ensure                = "Present"
      Action                = "Allow"
      Enabled               = "True"
      Profile               = ("Domain", "Private", "Public")
      Direction             = "InBound"
      LocalPort             = ("5151")         
      Protocol              = "TCP"
    }
    
    xFirewall QES
    {
      Name                  = "QES"
      DisplayName           = "Qlik Sense Engine"
      DisplayGroup          = "Qlik Sense"
      Ensure                = "Present"
      Action                = "Allow"
      Enabled               = "True"
      Profile               = ("Domain", "Private", "Public")
      Direction             = "InBound"
      LocalPort             = ("4747")         
      Protocol              = "TCP"
    }
    
    xFirewall QPS
    {
      Name                  = "QPS"
      DisplayName           = "Qlik Sense Proxy HTTPS"
      DisplayGroup          = "Qlik Sense"
      Ensure                = "Present"
      Action                = "Allow"
      Enabled               = "True"
      Profile               = ("Domain", "Private", "Public")
      Direction             = "InBound"
      LocalPort             = ("443")         
      Protocol              = "TCP"
    }
    
    xFirewall QPS-Auth
    {
      Name                  = "QPS-Auth"
      DisplayName           = "Qlik Sense Proxy Authentication HTTPS"
      DisplayGroup          = "Qlik Sense"
      Ensure                = "Present"
      Action                = "Allow"
      Enabled               = "True"
      Profile               = ("Domain", "Private", "Public")
      Direction             = "InBound"
      LocalPort             = ("4244")         
      Protocol              = "TCP"
    }
    
    xFirewall Qlik-Cert
    {
      Name                  = "Qlik-Cert"
      DisplayName           = "Qlik Sense Certificate Distribution"
      DisplayGroup          = "Qlik Sense"
      Ensure                = "Present"
      Action                = "Allow"
      Enabled               = "True"
      Profile               = ("Domain", "Private", "Public")
      Direction             = "InBound"
      LocalPort             = ("4444")         
      Protocol              = "TCP"
    }
  }
}

QlikConfig -ConfigurationData SiteConfig.psd1
Start-DscConfiguration -Verbose -Debug -Wait QlikConfig
