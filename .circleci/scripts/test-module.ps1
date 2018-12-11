$ErrorActionPreference = "Stop"

Install-Module Pester -Force
Import-Module ./Qlik-Cli.psd1

if ((Test-ModuleManifest -Path ./Qlik-Cli.psd1).Version -ne (Get-Module -Name Qlik-Cli).Version) {
  Write-Error -Message "Version does not match"
}

New-Item `
  -ItemType Directory `
  -Path /output/test-results/pester

Invoke-Pester `
  -EnableExit `
  -OutputFile /output/test-results/pester/results.xml

$mod = Import-LocalizedData -FileName Qlik-Cli.psd1 -BaseDirectory ./
Pop-Location
$content = $mod.NestedModules + $mod.RootModule |
  ForEach-Object {Get-Content -raw $_}
$content += "`nExport-ModuleMember -Function " +
  ($mod.FunctionsToExport -join ', ') +
  ' -Alias ' + ($mod.AliasesToExport -join ', ')
$content | Out-File ./Qlik-Cli-Merged.psm1 -Encoding utf8

Import-Module ./Qlik-Cli.psd1 -Force
$SplitCount = (Get-Command -Module Qlik-Cli).Count
Import-Module ./Qlik-Cli-Merged.psm1 -Force
$MergedCount = (Get-Command -Module Qlik-Cli-Merged).Count
if ($SplitCount -ne $MergedCount) {
  Write-Error  -Message ("Merged module contains wrong number of commands," `
                       + " has $MergedCount and should have $SplitCount")
}

New-Item `
  -ItemType Directory `
  -Path /output/workspace

Copy-Item ./Qlik-Cli-Merged.psm1 /output/workspace/Qlik-Cli.psm1
(Get-Module Qlik-Cli).Version.ToString() |
  Out-File /output/workspace/version -Encoding utf8
