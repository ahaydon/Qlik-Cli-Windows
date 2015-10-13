# Desired State Configuration Example

## Installation

* Windows Management Framework 5 is required for the DSC module, and is installed automatically if using the Packer template.
* Clone this repo:

  ```
  git clone git@github.com:ahaydon/qlik-cli.git && cd qlik-cli
  ```

The module can be installed by copying the files in the Modules folder to C:\Windows\System32\WindowsPowerShell\v1.0\Modules\QlikResources\, the module will then be loaded and ready to use with a DSC manifest.

* Apply the configuration

Edit the SiteConfig.psd1 file and define the servers in the Qlik Sense site, then open a PowerShell console and cd to the manifests folder, finally run the following command.

  ```sh
  .\QlikConfig.ps1
  ```

## Export/Import configuration

It is possible to export configuration from Sense by chaining Get-Qlik commands together to build and array of objects and then using the ConvertTo-Json cmdlet to save the result in JSON format.

  ```sh
  (Get-QlikNode) + (Get-QlikProxy) + (Get-QlikCustomProperty) | ConvertTo-Json -Depth 5 | Out-File sensebackup.json
  ```

Additional Get commands can be added to the chain to export more object types from the repository. The JSON file can then be used with the QlikRestore DSC manifest to apply the configuration to another site or restore the server. Copy the sensebackup.json file to the folder where the QlikRestore.ps1 file is located and run the following command.

  ```sh
  .\QlikRestore.ps1
  ```