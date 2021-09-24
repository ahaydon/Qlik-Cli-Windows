[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "For testing purposes only")]
param(
    $QlikSenseSetupUri = 'https://da3hntz84uekx.cloudfront.net/QlikSense/14.20/0/_MSI/Qlik_Sense_setup.exe',
    $QlikSenseLocalPath = 'C:\kitchen-cache\Qlik Sense May 2021\Qlik_Sense_setup.exe'
)

$InformationPreference = 'Continue'

# --- Workarounds for PowerShell 4 ---
if (! (Get-Command -Name 'Write-Information' -ErrorAction SilentlyContinue)) {
    New-Alias -Name 'Write-Information' -Value 'Write-Host'
}

if (! (Get-Command -Name 'New-LocalUser' -ErrorAction SilentlyContinue)) {
    function New-LocalUser {
        param (
            $FullName,
            $Name,
            [securestring]$Password,
            [switch]$PasswordNeverExpires,
            [switch]$UserMayNotChangePassword
        )

        $UserFlags = 0
        if ($PasswordNeverExpires.IsPresent) { $UserFlags += 65536 }
        if ($UserMayNotChangePassword.IsPresent) { $UserFlags += 64 }

        $Computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"

        $LocalAdmin = $Computer.Create('User', $Name)
        $LocalAdmin.SetPassword([System.Runtime.InteropServices.Marshal]::PtrToStringBSTR([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)))
        $LocalAdmin.SetInfo()
        $LocalAdmin.FullName = $FullName
        $LocalAdmin.SetInfo()
        $LocalAdmin.UserFlags = $UserFlags
        $LocalAdmin.SetInfo()
    }
}

if (! (Get-Command -Name 'Add-LocalGroupMember' -ErrorAction SilentlyContinue)) {
    function Add-LocalGroupMember {
        param (
            [string]$Group,
            [string[]]$Member
        )

        $LocalGroup = [ADSI]"WinNT://$Env:COMPUTERNAME/$Group,group"
        $Member | ForEach-Object { $LocalGroup.Add("WinNT://$Env:COMPUTERNAME/$_,user") }
    }
}
# --- End of PowerShell 4 workarounds ---

$Hostname = ([System.Net.Dns]::GetHostEntry('localhost')).hostname

# --- Workaround for Kitchen-DSC ---
Write-Information 'Applying workaround for DSC on kitchen.ci'
$key = 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\DSC'
if (! (Test-Path $key)) {
    New-Item -Path $key | Out-Null
}
New-ItemProperty -Path $key -Name 'PSDscAllowPlainTextPassword' -Value 1 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $key -Name 'PSDscAllowDomainUser' -Value 1 -PropertyType DWORD -Force | Out-Null
# --- End of workaround for Kitchen-DSC

Write-Information "Disabling Password Complexity"
secedit /export /cfg c:\secpol.cfg | Out-Null
(Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY | Out-Null
Remove-Item -Force c:\secpol.cfg -Confirm:$false

# WinRM HTTPS listener required for PSRemoting from Linux
Write-Information 'Enabling HTTPS listener for WinRM'
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName ([System.Net.Dns]::GetHostName())
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force | Out-Null
Set-Item WSMan:\localhost\Service\Auth\Basic $true
New-NetFirewallRule `
    -DisplayName 'Windows Remote Management (HTTPS-In)' `
    -Name 'Windows Remote Management (HTTPS-In)' `
    -Profile Any `
    -LocalPort 5986 `
    -Protocol TCP | Out-Null

# --- Begin Install of Qlik Sense ---
$password = ConvertTo-SecureString -String 'Qlik1234' -AsPlainText -Force
Write-Information 'Creating Qlik admin user'
New-LocalUser `
    -Name qlik `
    -Password $password `
    -FullName 'Qlik Admin' `
    -PasswordNeverExpires | Out-Null
Write-Information 'Creating Qlik Sense service account'
New-LocalUser `
    -Name qservice `
    -Password $password `
    -FullName 'Qlik Sense Service Account' `
    -PasswordNeverExpires `
    -UserMayNotChangePassword | Out-Null
Add-LocalGroupMember -Group Administrators -Member qservice, qlik

Write-Information 'Creating Qlik Sense cluster share'
New-Item -Path C:\QlikShare -ItemType Directory | Out-Null
New-SmbShare -Name QlikShare -Path C:\QlikShare -FullAccess Everyone | Out-Null

if (!(Test-Path $QlikSenseLocalPath)) {
    Write-Information 'Downloading Qlik Sense'
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $QlikSenseSetupUri -OutFile $QlikSenseLocalPath
    $ProgressPreference = 'Continue'
}

Write-Information 'Installing Qlik Sense'
$spc = @"
<?xml version="1.0"?>
<SharedPersistenceConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <DbUserName>qliksenserepository</DbUserName>
  <DbUserPassword>Qlik1234</DbUserPassword>
  <DbHost>localhost</DbHost>
  <DbPort>4432</DbPort>
  <CreateCluster>true</CreateCluster>
  <RootDir>\\$Hostname\QlikShare</RootDir>
  <StaticContentRootDir>\\$Hostname\QlikShare\StaticContent</StaticContentRootDir>
  <CustomDataRootDir>\\$Hostname\QlikShare\CustomData</CustomDataRootDir>
  <ArchivedLogsDir>\\$Hostname\QlikShare\ArchivedLogs</ArchivedLogsDir>
  <AppsDir>\\$Hostname\QlikShare\Apps</AppsDir>
  <InstallLocalDb>true</InstallLocalDb>
  <ConfigureDbListener>true</ConfigureDbListener>
  <ListenAddresses>*</ListenAddresses>
  <IpRange>0.0.0.0/0,::/0</IpRange>
  <ConfigureLogging>true</ConfigureLogging>
  <SetupLocalLoggingDb>true</SetupLocalLoggingDb>
  <QLogsWriterPassword>Qlik1234</QLogsWriterPassword>
  <QLogsReaderPassword>Qlik1234</QLogsReaderPassword>
  <QLogsHostname>localhost</QLogsHostname>
  <QLogsPort>4432</QLogsPort>
  <JoinCluster>false</JoinCluster>
</SharedPersistenceConfiguration>
"@
$spc | Out-File spc.cfg
$spc_file = Get-Item spc.cfg

$args = @(
    '-silent',
    'accepteula=1',
    'dbpassword="Qlik1234"',
    "hostname=$Hostname",
    "userwithdomain=$Hostname\qservice",
    'userpassword="Qlik1234"',
    "spc=$($spc_file.FullName)"
)
Start-Process `
    -FilePath $QlikSenseLocalPath `
    -ArgumentList $args `
    -Wait

Write-Information 'Opening firewall port for Hub/QMC access'
New-NetFirewallRule `
    -DisplayName 'Qlik Sense Proxy (HTTPS-In)' `
    -Name 'Qlik Sense Proxy (HTTPS-In)' `
    -Group 'Qlik Sense' `
    -Profile Any `
    -LocalPort 443 `
    -Protocol TCP | Out-Null

Write-Information 'Opening firewall port for QRS API'
New-NetFirewallRule `
    -DisplayName 'Qlik Sense Repository API (HTTPS-In)' `
    -Name 'Qlik Sense Repository API (HTTPS-In)' `
    -Group 'Qlik Sense' `
    -Profile Any `
    -LocalPort 4242 `
    -Protocol TCP | Out-Null

Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
      public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
      }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
do {
    try {
        Write-Information "Waiting for services to be ready..."
        $result = Invoke-RestMethod https://localhost/qps/user -ErrorAction Stop
    }
    catch {
        Start-Sleep -Seconds 10
    }
} until ($result.session -eq 'inactive')

# --- End install of Qlik Sense ---
