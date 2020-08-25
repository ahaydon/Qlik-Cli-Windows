# Contributing to Qlik-Cli

## Dependencies

- Windows PowerShell 4+ or PowerShell Core
- Git - for cloning and pushing changes
- Pester - PS module for running unit tests
- PSScriptAnalyzer - PS module to check code formatting
- PlatyPS - PS module to update help files

## Get the code
```sh
git clone https://github.com/ahaydon/Qlik-Cli-Windows.git
```

## Code structure
- docs - markdown documentation generated by PlatyPS
- functions - scripts containing internal functions
- resources - scripts containing exported commands
- tests - Pester unit test scripts

## Pull request checks
Before making a pull request you should check that your code changes will pass the automated checks, this will help to prevent you request being rejected.

1. Run unit tests
```powershell
Invoke-Pester
```
2. Check you code conforms to best practices
```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -ReportSummary
```
3. Check your code meets the code formatting standards of this repo
```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -ReportSummary -Settings CodeFormatting -ExcludeRule PSAlignAssignmentStatement
```
4. Ensure documentation is up to date
```powershell
Remove-Module Qlik-Cli; Import-Module ./Qlik-Cli.psd1 -Force
Update-MarkdownHelpModule -Path ./docs -RefreshModulePage -ModulePagePath ./docs/index.md -UpdateInputOutput -Force
```
5. Update the markdown help files by adding descriptions and examples for any cmdlet that you have added or changed