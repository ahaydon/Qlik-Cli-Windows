[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "Deprecation warning")]
param ()

$ErrorActionPreference = "Stop"

if ((Test-ModuleManifest -Path ./Qlik-Cli.psd1).Version -le (Find-Module -Name Qlik-Cli).Version) {
    Write-Error "Module version already exists"
}

$password = ConvertTo-SecureString -String $env:GITHUB_TOKEN -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("ahaydon", $password)
$release = Invoke-RestMethod `
    -Method Get `
    -Uri "https://api.github.com/repos/ahaydon/qlik-cli/releases/latest" `
    -Credential $credential

if ((Test-ModuleManifest -Path ./Qlik-Cli.psd1).Version -lt [System.Version]$release.tag_name.Substring(1)) {
    Write-Error "Module version must be newer than last published version"
}

$version = (Test-ModuleManifest -Path ./Qlik-Cli.psd1).Version
$release = $null
$null = try {
    $release = Invoke-RestMethod `
        -Method Get `
        -Uri "https://api.github.com/repos/ahaydon/qlik-cli/releases/tags/$version" `
        -Credential $credential `
        -ErrorAction SilentlyContinue
}
catch [System.Net.Http.HttpRequestException] {
    if ($_.Exception.Response.StatusCode -ne "NotFound") {
        Throw $_
    }
    $Error | Out-Null #clear the error so we exit cleanly
}

if ($release) {
    Write-Error "Module version already exists"
}
