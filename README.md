# About
Qlik-Cli is a PowerShell module that provides a command line interface for managing a Qlik Sense environment. The module provides a set of commands for viewing and editing configuration settings, as well as managing tasks and other features available through the APIs.
# Installation
The module can be installed by copying the Qlik-Cli.psm1 file to C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Qlik-Cli\, or by entering Import-Module Qlik-Cli.psm1 from the directory containing the module. The module will then be loaded and ready to use from the PowerShell console, you should be able to see a list of available commands by running Get-Help Qlik.
# Examples
A number of files are provided to demonstrate the use of the module with Vagrant to automate the deployment of a multi-node Qlik Sense environment, this requires that Vagrant and VirtualBox are installed and can be used by running 'Vagrant Up' at the command prompt in the folder where this repository has been cloned.
