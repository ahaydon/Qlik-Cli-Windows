$drive = (Gwmi Win32_mappedLogicalDisk -filter "ProviderName='\\\\vboxsrv\\setup_files'").name
$dotnet_url = "http://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe"

if (!(Test-Path "$drive\NDP452-KB2901907-x86-x64-AllOS-ENU.exe")) {
    Write-Host "Downloading .Net 4.5.2 setup file"
    $dotnet_installer = "$env:temp\NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
    (New-Object System.Net.WebClient).DownloadFile($dotnet_url, $dotnet_installer)
} else {
  $dotnet_installer = "$drive\NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
}

write-host "Compiling .Net Assemblies"
start "$env:windir\microsoft.net\framework\v4.0.30319\ngen.exe" "executequeueditems" > $null
start "$env:windir\microsoft.net\framework64\v4.0.30319\ngen.exe" "executequeueditems" > $null
write-host "Installing .Net Framework"
start $dotnet_installer @("/q", "/norestart") -wait
write-host "Compiling .Net Assemblies"
start "$env:windir\microsoft.net\framework\v4.0.30319\ngen.exe" "executequeueditems" > $null
start "$env:windir\microsoft.net\framework64\v4.0.30319\ngen.exe" "executequeueditems" > $null
