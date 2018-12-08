## About
Qlik-Cli is a PowerShell module that provides a command line interface for managing a Qlik Sense environment. The module provides a set of commands for viewing and editing configuration settings, as well as managing tasks and other features available through the APIs.

[![CircleCI](https://circleci.com/gh/ahaydon/Qlik-Cli.svg?style=svg)](https://circleci.com/gh/ahaydon/Qlik-Cli) Publish to PowerShell Gallery and GitHub releases

The desired state configuration module has now been moved to https://github.com/ahaydon/Qlik-DSC
## Usage
There are many cmdlets in the Qlik-Cli module for viewing and managing Sense resources, a common scenario is triggering tasks from an external application. This can be achieved using the Start-QlikTask command followed by a task name or ID, names with spaces must be enclosed in quotes. e.g.
```powershell
Start-QlikTask "Reload Operations Monitor" -wait | Wait-QlikExecution
```
The command in the example triggers a task to run and then uses the Wait-QlikExecution command to monitor the task execution, providing status updates to the console as the task progresses and only returning when the task is complete.
We can also use powershell to download apps that we want to move to another environment, by issuing a Get-QlikApp command with a filter we can restrict which apps will be downloaded, and then using pipelining the results can be passed to the Export-QlikApp command to download them.
```powershell
Get-QlikApp -filter "stream.name eq 'My Stream'" | Export-QlikApp
```
## Installation
PowerShell 4.0 is required to run Qlik-Cli. You can use the following command to check the version installed on your system.
```powershell
$PSVersionTable.PSVersion
```
Ensure you can run script by changing the execution policy, you can change this for the machine by running PowerShell as Administrator and executing the command
```powershell
Set-ExecutionPolicy RemoteSigned
```
If you do not have administrator rights you can change the policy for your user rather than the machine using
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```
If you have PowerShell 5 or later you can install the module from NuGet using the following command.
```powershell
Get-PackageProvider -Name NuGet -ForceBootstrap
Install-Module Qlik-Cli
```
Otherwise, the module can be installed by downloading and extracting the files to C:\Program Files\WindowsPowerShell\Modules\Qlik-Cli\, the module will then be loaded the next time you open a PowerShell console. You can also load the module for the current session using the Import-Module command and providing the name or path to the module.
```powershell
Import-Module Qlik-Cli
Import-Module .\Qlik-Cli.psd1
```
Once the module is loaded you can view a list of available commands by using the Get-Help PowerShell command.
```powershell
Get-Help Qlik
```
### Connecting with certificates
Invoking a cmdlet will trigger the Connect-Qlik command with default parameters, this will attempt to locate a certificate from the certificate stores. Alternatively a certificate can be piped into the cmdlet using built-in powershell cmdlets to retrieve the certificate from the Windows certificate store.
```powershell
Get-ChildItem cert:CurrentUser\My | Where-Object { $_.FriendlyName -eq 'QlikClient' } | Connect-Qlik sense-central
```
## Examples
A number of files are provided to demonstrate the use of the module with Vagrant to automate the deployment of a multi-node Qlik Sense site, this requires that Vagrant and VirtualBox are installed and can be used by running commands in their relevant folders. See readme files in each of the sub-folders for more information.

## License
This software is made available "AS IS" without warranty of any kind. Qlik support agreement does not cover support for this software.
