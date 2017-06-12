## About
Qlik-Cli is a PowerShell module that provides a command line interface for managing a Qlik Sense environment. The module provides a set of commands for viewing and editing configuration settings, as well as managing tasks and other features available through the APIs.
## Usage
There are many cmdlets in the Qlik-Cli module for viewing and managing Sense resources, a common scenario is triggering tasks from an external application. This can be achieved using the Start-QlikTask command followed by a task name or ID, names with spaces must be enclosed in quotes. e.g.
```sh
Start-QlikTask "Reload Operations Monitor" -wait | Wait-QlikExecution
```
The command in the example triggers a task to run and then uses the Wait-QlikExecution command to monitor the task execution, providing status updates to the console as the task progresses and only returning when the task is complete.
We can also use powershell to download apps that we want to move to another environment, by issuing a Get-QlikApp command with a filter we can restrict which apps will be downloaded, and then using pipelining the results can be passed to the Export-QlikApp command to download them.
```sh
Get-QlikApp -filter "stream.name eq 'My Stream'" | Export-QlikApp
```
## Installation
PowerShell 4.0 is required to run Qlik-Cli. You can use the following command to check the version installed on your system.
```sh
$PSVersionTable.PSVersion
```
Ensure you can run script by changing the execution policy, you can change this for the machine by running PowerShell as Administrator and executing the command
```sh
Set-ExecutionPolicy RemoteSigned
```
If you do not have administrator rights you can change the policy for your user rather than the machine using
```sh
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```
The module can be installed by copying the Qlik-Cli.psm1 file to C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Qlik-Cli\, the module will then be loaded and ready to use from the PowerShell console. You can also load the module using the Import-Module command.
```sh
Import-Module Qlik-Cli.psm1
```
Once the module is loaded you can view a list of available commands by using the Get-Help PowerShell command.
```sh
Get-Help Qlik
```
### Connecting with certificates
Invoking a cmdlet will trigger the Connect-Qlik command with default parameters, this will attempt to locate a certificate from the certificate stores. Alternatively a certificate can be piped into the cmdlet using built-in powershell cmdlets to retrieve the certificate from the Windows certificate store.
```sh
gci cert:currentuser\my | where { $_.friendlyname -eq 'QlikClient' } | Connect-Qlik sense-central
```
## Examples
A number of files are provided to demonstrate the use of the module with Vagrant to automate the deployment of a multi-node Qlik Sense site, this requires that Vagrant and VirtualBox are installed and can be used by running commands in their relevant folders. See readme files in each of the sub-folders for more information.

## License
This software is made available "AS IS" without warranty of any kind. Qlik support agreement does not cover support for this software.
