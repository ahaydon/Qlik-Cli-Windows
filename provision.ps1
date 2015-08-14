$config = (Get-Content c:\vagrant\config.json -raw) | ConvertFrom-Json
$license = (Get-Content c:\vagrant\license.json -raw) | ConvertFrom-Json
$computer = $config.servers | where { $_.name -eq $env:computername }

If( (Get-CimInstance SoftwareLicensingProduct -ComputerName $env:computername -Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'").licensestatus -eq 0 ) {
  $winver = (Get-WmiObject Win32_OperatingSystem).Version
  If( $license.windows.$winver )
  {
    Write "Activating Windows"
    $key = $license.windows.$winver
    $service = Get-WmiObject -Query "SELECT * FROM SoftwareLicensingService"
    $service.InstallProductKey($key) > $null
    $service.RefreshLicenseStatus() > $null
  } else {
    Write "Product key not found for Windows $winver"
  }
}

$dotnet = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
If( $dotnet.Release -lt 379893 )
{
  Write-Host "Installing .Net Framework"
  unblock-file "c:\shared\NDP452-KB2901907-x86-x64-AllOS-ENU.exe" > $null
  $params = @(
    "/q",
    "/norestart"
  )
  start "c:\shared\NDP452-KB2901907-x86-x64-AllOS-ENU.exe" $params -wait

} else {
  $config.servers | foreach { Write "$($_.ip) $($_.name)" | Out-File "C:\Windows\System32\drivers\etc\hosts" -Append -Encoding "UTF8" }
  Write-Host "Disabling Remote Desktop Network Level Authentication"
  (Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName $env:computerName -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0) > $null

  Write-Host "Setting time zone to GMT Standard Time"
  tzutil /s "GMT Standard Time" > $null

  Write-Host "Adding British keyboard layout"
  Set-WinUserLanguageList -LanguageList en-GB -force
  Set-WinUILanguageOverride -Language en-GB

  Write-Host "Updating Internet Settings"
  # Always open Internet Explorer on the desktop
  $path = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Internet Explorer\Main"
  Set-ItemProperty -Path $path -Name AssociationActivationMode -Value 2 -Force
  # Add computer to Local Intranet zone
  $path = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"
  New-Item -Path $path -Name $computer.name > $null
  $path += "\$($computer.name)"
  Set-ItemProperty -Path $path -Name https -Value 1 > $null

  Write-Host "Configuring firewall rules"
  &{
    New-NetFirewallRule -DisplayName "Qlik Sense Proxy HTTPS" -Action Allow -Direction Inbound -LocalPort 443 -Protocol TCP
    New-NetFirewallRule -DisplayName "Qlik Sense Proxy Authentication HTTPS" -Action Allow -Direction Inbound -LocalPort 4244 -Protocol TCP
    New-NetFirewallRule -DisplayName "Qlik Sense Certificate Distribution" -Action Allow -Direction Inbound -LocalPort 4444 -Protocol TCP
    New-NetFirewallRule -DisplayName "Qlik Sense Repository Replication" -Action Allow -Direction Inbound -LocalPort 4241 -Protocol TCP
    New-NetFirewallRule -DisplayName "Qlik Sense Scheduler" -Action Allow -Direction Inbound -LocalPort 4242 -Protocol TCP
    New-NetFirewallRule -DisplayName "Qlik Sense Engine" -Action Allow -Direction Inbound -LocalPort 4747 -Protocol TCP
    New-NetFirewallRule -DisplayName "Qlik Sense Repository Service" -Action Allow -Direction Inbound -LocalPort 4239 -Protocol TCP
    New-NetFirewallRule -DisplayName "Qlik Sense Scheduler Master" -Action Allow -Direction Inbound -LocalPort 5050 -Protocol TCP
    New-NetFirewallRule -DisplayName "Qlik Sense Scheduler Slave" -Action Allow -Direction Inbound -LocalPort 5151 -Protocol TCP
  } | format-table -Property DisplayName,PrimaryStatus -AutoSize -HideTableHeaders

  Write-Host "Installing Qlik Sense"
  unblock-file "c:\shared\sense201\Qlik_Sense_setup.exe" > $null
  $params = $config.sense.install + $computer.sense.install
  If( $computer.sense.syncnode ) { $params += "-syncnode" }
  $installed_services = @()
  If( $computer.sense.proxy ) { $installed_services += "Proxy" }
  If( $computer.sense.engine ) { $installed_services += "Engine" }
  If( $computer.sense.scheduler ) { $installed_services += "Scheduler" }
  # Master Scheduler must be installed on central node
  If( $computer.sense.central -And $installed_services -notcontains "Scheduler" ) { $installed_services += "Scheduler" }
  # Slave Schedulers must have the Engine service
  If( $installed_services -contains "Scheduler" -And $installed_services -notcontains "Engine" ) { $installed_services += "Engine" }
  If( $installed_services.Count -gt 0 )
  {
    $params += "-a"
    $params += $installed_services
  }
  $params += @( "-log"; "c:\vagrant\log\$($computer.name).log" )
  $params = $params | ? {$_}
  start "c:\shared\sense201\Qlik_Sense_setup.exe" $params -wait

  If( $computer.sense.central )
  {
    Write-Host "Applying Qlik Sense license"
    Set-QlikLicense -serial "$($license.sense.serial)" -control "$($license.sense.control)" -name "$($license.sense.name)" -org "$($license.sense.org)" -lef "$($license.sense.lef)" | format-list -Property serial,name,organization,isExpired,expiredReason,isBlacklisted

    If( $computer.sense.service -notcontains "Scheduler" )
    {
      Write-Host "Creating network shares"
      &{
        New-SmbShare "QlikLog" "C:\ProgramData\Qlik\Sense\Log" -CachingMode None -FullAccess "Administrators"
        New-SmbShare "QlikArchiveLog" "C:\ProgramData\Qlik\Sense\Repository\Archived Logs" -CachingMode None -FullAccess "Administrators"
      } | format-table -Property Name,Path,ShareState -AutoSize -HideTableHeaders

      Write-Host "Updating data connections"
      Do
      {
        $count ++
        sleep $count
        $conn = Get-QlikDataConnection -filter "name eq 'ServerLogFolder'" | Update-QlikDataConnection -ConnectionString "\\$($computer.name)\QlikLog"
      } Until ($count -eq 10 -Or $conn -ne $null)
      Get-QlikDataConnection -filter "name eq 'ArchivedLogsFolder'" | Update-QlikDataConnection -ConnectionString "\\$($computer.name)\QlikArchiveLog" > $null

      Write-Host "Configuring system rules"
      Get-QlikRule -filter "name eq 'ResourcesToNonCentralNodes'" | Update-QlikRule -rule '((node.isCentral="false"))' > $null
      $group = New-QlikUserAccessGroup "License rule to grant user access"
      New-QlikRule -name $group.name -category license -rule '((user.roles="RootAdmin"))' -filter "License.UserAccessGroup_$($group.id)" -actions 1 -comment "Rule to setup automatic user access" -rulecontext hub > $null
      # If the central node should not be a scheduler set it to master only
      If( ! $computer.sense.scheduler )
      {
        Get-QlikScheduler local | Update-QlikScheduler -type master > $null
      }
      # If the central node should not be an application engine remove it from proxy load balancing
      If( ! $computer.sense.engine )
      {
        Get-QlikVirtualProxy | Update-QlikVirtualProxy -engine $null > $null
      }
    }

  } else {
    $central = $config.servers | where { $_.sense.central -eq $true }
    Write-Host "Registering with central node $($central.name)"
    Connect-Qlik $central.name -TrustAllCerts > $null
    $params = @{
      engine=$($installed_services -contains "engine");
      proxy=$($installed_services -contains "proxy");
      scheduler=$($installed_services -contains "scheduler");
    }
    Register-QlikNode @params
    
    If( $computer.sense.engine )
    {
      Write-Host "Adding node to virtual proxy configurations"
      Get-QlikVirtualProxy | Add-QlikVirtualProxy -engine $computer.name > $null
    }
    If( $computer.sense.proxy )
    {
      Write-Host "Adding nodes to virtual proxy configuration"
      $engine = @( Get-QlikVirtualProxy -filter "description eq 'Central Proxy (Default)'" | select -expandproperty loadbalancingservernodes | foreach { $_.id } )
      Get-QlikVirtualProxy | Update-QlikVirtualProxy -engine $engine > $null
    }
  }
}
