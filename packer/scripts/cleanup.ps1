# Let's cleanup!
#
# See http://www.hurryupandwait.io/blog/in-search-of-a-light-weight-windows-vagrant-box
# for details!

Write-Host "Disabling Remote Desktop Network Level Authentication"
(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName $env:computerName -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0) > $null

# Reduce PageFile size
$System = GWMI Win32_ComputerSystem -EnableAllPrivileges
$System.AutomaticManagedPagefile = $False
$System.Put()

$CurrentPageFile = gwmi -query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"
$CurrentPageFile.InitialSize = 512
$CurrentPageFile.MaximumSize = 512
$CurrentPageFile.Put()

# Cleanup update uninstallers
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

 # Remove unnecessary features
 @('Desktop-Experience',
  'InkAndHandwritingServices',
  'Server-Media-Foundation',
  'Powershell-ISE') | Remove-WindowsFeature

 Get-WindowsFeature | 
? { $_.InstallState -eq 'Available' } | 
Uninstall-WindowsFeature -Remove

# Defrag C
Optimize-Volume -DriveLetter C

wget http://download.sysinternals.com/files/SDelete.zip -OutFile sdelete.zip
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
[System.IO.Compression.ZipFile]::ExtractToDirectory("sdelete.zip", ".") 

reg.exe ADD "HKCU\Software\Sysinternals\SDelete" /v EulaAccepted /t REG_DWORD /d 1 /f
./sdelete.exe -z c: