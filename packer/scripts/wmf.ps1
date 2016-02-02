$drive = (Gwmi Win32_mappedLogicalDisk -filter "ProviderName='\\\\vboxsrv\\setup_files'").name
$wmf_url = "https://download.microsoft.com/download/3/F/D/3FD04B49-26F9-4D9A-8C34-4533B9D5B020/Win8.1AndW2K12R2-KB3066437-x64.msu"

if (!(Test-Path "$drive\Win8.1AndW2K12R2-KB3066437-x64.msu")) {
    Write-Host "Downloading Windows Management Framework 5.0 Preview setup file"
    $wmf_installer = "$env:temp\Win8.1AndW2K12R2-KB3066437-x64.msu"
    (New-Object System.Net.WebClient).DownloadFile($wmf_url, $wmf_installer)
} else {
  $wmf_installer = "$drive\Win8.1AndW2K12R2-KB3066437-x64.msu"
}
Write-Host $wmf_installer

Write-Host "Installing Windows Management Framework 5.0 Preview"
unblock-file $wmf_installer > $null
start $wmf_installer @("/quiet", "/norestart") -wait
