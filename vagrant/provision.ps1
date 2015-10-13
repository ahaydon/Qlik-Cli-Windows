$config = (Get-Content c:\vagrant\config.json -raw) | ConvertFrom-Json
$computer = $config.servers | where { $_.name -eq $env:computername }

$config.servers | foreach { Write "$($_.ip) $($_.name)" | Out-File "C:\Windows\System32\drivers\etc\hosts" -Append -Encoding "UTF8" }

Write-Host "Updating Internet Settings"
# Always open Internet Explorer on the desktop
$path = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Internet Explorer\Main"
Set-ItemProperty -Path $path -Name AssociationActivationMode -Value 2 -Force
# Add computer to Local Intranet zone
$path = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"
New-Item -Path $path -Name $computer.name > $null
$path += "\$($computer.name)"
Set-ItemProperty -Path $path -Name https -Value 1 > $null

Write-Host "Installing Qlik Sense"
unblock-file "c:\vagrant\setup_files\Qlik_Sense_setup.exe" > $null
$params = $config.sense.install + $computer.sense.install
If( -not $computer.sense.central ) { $params += "-syncnode" }
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
start "c:\vagrant\setup_files\Qlik_Sense_setup.exe" $params -wait

If( $computer.sense.central ) {
  winrm set winrm/config/client '@{TrustedHosts="*"}'
}

Get-PackageProvider -Name NuGet -ForceBootstrap
Install-Module -Name xNetworking -Confirm -Force
Install-Module -Name xSmbShare -Confirm -Force
Install-Module -Name xPSDesiredStateConfiguration -Confirm -Force

