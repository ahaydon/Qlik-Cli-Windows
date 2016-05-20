## About
This is a fork from original [ahaydon/Qlik-Cli] (https://github.com/ahaydon/Qlik-Cli])

I have contributed with three new functions that do possible massive export and import of Qlik applications and create Qlik rules from a file with psobjects

Functions
- Export-QlikAppList 
- Import-QlikAppList
- New-QlikRulesFromFIle
	
## Installation
The module can be installed by copying the Qlik-Cli.psm1 file to C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Qlik-Cli\, the module will then be loaded and ready to use from the PowerShell console. You can also load the module using the Import-Module command.
```sh
Import-Module Qlik-Cli.psm1
```
Once the module is loaded you can view a list of available commands by using the Get-Help PowerShell command.
```sh
Get-Help Qlik
```
## Usage
### Connecting with certificates
Invoking a cmdlet will trigger the Connect-Qlik command with default parameters, this will attempt to locate a certificate from the certificate stores. Alternatively a certificate can be piped into the cmdlet using built-in powershell cmdlets to retrieve the certificate from the Windows certificate store.
```sh
gci cert:currentuser\my | where { $_.friendlyname -eq 'QlikClient' } | Connect-Qlik sense-central
```
## Examples
A number of files are provided to demonstrate the use of the module with Vagrant to automate the deployment of a multi-node Qlik Sense site, this requires that Vagrant and VirtualBox are installed and can be used by running commands in their relevant folders. See readme files in each of the sub-folders for more information.

## License
This software is made available "AS IS" without warranty of any kind. Qlik support agreement does not cover support for this software.
