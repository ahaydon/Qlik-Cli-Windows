## About
Qlik-Cli is a PowerShell module that provides a command line interface for managing a Qlik Sense environment. The module provides a set of commands for viewing and editing configuration settings, as well as managing tasks and other features available through the APIs.
## Installation
The module can be installed by copying the Qlik-Cli.psm1 file to C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Qlik-Cli\, the module will then be loaded and ready to use from the PowerShell console. You can also load the module using the Import-Module command.
```sh
Import-Module Qlik-Cli.psm1
```
Once the module is loaded you can view a list of available commands by using the Get-Help PowerShell command.
```sh
Get-Help Qlik
```
## Examples
A number of files are provided to demonstrate the use of the module with Vagrant to automate the deployment of a multi-node Qlik Sense site, this requires that Vagrant and VirtualBox are installed and can be used by running commands in their relevant folders. See readme files in each of the sub-folders for more information.

## License
This software is made available "AS IS" without warranty of any kind. Qlik support agreement does not cover support for this software.