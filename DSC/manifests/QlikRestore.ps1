Configuration QlikRestore
{
  Import-DSCResource -ModuleName QlikResources

  $config = (Get-Content sensebackup.json -raw) | ConvertFrom-Json
  
  QlikConnect vagrant
  {
    Username = "sense1\vagrant"
    Computername = $AllNodes.Where{$_.Central}.NodeName
  }

  $config | where { $_.schemaPath -eq "License" } | foreach {
    QlikLicense SiteLicense
    {
      Serial = $_.serial
      Control = (Read-Host -Prompt 'Enter license control number')
      Name = $_.name
      Organization = $_.organization
      Lef = $_.lef
      Ensure = "Present"
      DependsOn = "[QlikConnect]vagrant"
    }
  }
  
  $config | where { $_.schemaPath -eq "CustomPropertyDefinition" } | foreach {
    QlikCustomProperty $_.id
    {
      Name = $_.name
      ChoiceValues = $_.choiceValues
      ObjectTypes = $_.objectTypes
      Ensure = "Present"
      DependsOn = "[QlikLicense]SiteLicense"
    }
  }

  $config | where { $_.schemaPath -eq "DataConnection" } | foreach {
    QlikDataConnection $_.id
    {
      Name = $_.name
      ConnectionString = $_.connectionString
      Type = $_.type
      Ensure = "Present"
      DependsOn = "[QlikLicense]SiteLicense"
    }
  }
  
  $config | where { $_.schemaPath -eq "ServerNodeConfiguration" } | foreach {
    QlikNode $_.id
    {
      HostName     = $_.hostName
      Ensure       = "Present"
      Proxy        = $_.proxyEnabled
      Engine       = $_.engineEnabled
      Printing     = $_.printingEnabled
      Scheduler    = $_.schedulerEnabled
      CustomProperties = @($_.customProperties | foreach { "$($_.definition.name)=$($_.value)" })
      DependsOn = @($_.customProperties | foreach { "[QlikCustomProperty]$($_.definition.id)" })
    }
  }
  
  $config | where { $_.schemaPath -eq "SystemRule" } | foreach {
    QlikRule $_.id
    {
      Name = $_.name
      Rule = $_.rule
      Category = $_.category
      Actions = $_.actions
      Comment = $_.comment
      RuleContext = switch($_.ruleContext){0{'both'};1{'hub'};2{'qmc'}}
      Ensure = "Present"
      DependsOn = "[QlikLicense]SiteLicense"
    }
  }
  
  $config | where { $_.schemaPath -eq "VirtualProxyConfig" } | foreach {
    QlikVirtualProxy $_.id
    {
      Prefix = $_.prefix
      Description = $_.description
      SessionCookieHeaderName = $_.sessionCookieHeaderName
      #loadBalancingServerNodes = @( $_.loadBalancingServerNodes | foreach { @{id=$_.id} } )
      Ensure = "Present"
      DependsOn = "[QlikLicense]SiteLicense"
    }
  }
}

QlikRestore
Start-DscConfiguration -Verbose -Debug -Wait QlikRestore

