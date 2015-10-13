$drive = (Gwmi Win32_mappedLogicalDisk -filter "ProviderName='\\\\vboxsrv\\setup_files'").name
$wmf_url = "http://download.microsoft.com/download/4/9/6/496E0D89-F3B0-4FB0-B110-5F135C30325F/WindowsBlue-KB3055381-x64.msu"

if (!(Test-Path "$drive\WindowsBlue-KB3055381-x64.msu")) {
    Write-Host "Downloading Windows Management Framework 5.0 Preview setup file"
    $wmf_installer = "$env:temp\WindowsBlue-KB3055381-x64.msu"
    (New-Object System.Net.WebClient).DownloadFile($wmf_url, $wmf_installer)
} else {
  $wmf_installer = "$drive\WindowsBlue-KB3055381-x64.msu"
}
Write-Host $wmf_installer

Write-Host "Installing Windows Management Framework 5.0 Preview"
unblock-file $wmf_installer > $null
start $wmf_installer @("/quiet", "/norestart") -wait
