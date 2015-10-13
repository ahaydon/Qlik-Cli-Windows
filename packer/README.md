# Packer Example Template

Based on [Packer Community Templates](https://github.com/mefellows/packer-community-templates) for Windows environments and modified to include dependencies for Qlik Sense and the DSC modules provided here.

## Running 

* Install [Packer](https://github.com/mitchellh/packer/)
* Clone this repo:

  ```
  git clone git@github.com:ahaydon/qlik-cli.git && cd qlik-cli
  ```

* Run Packer 

  Common practice is to create intermediate boxes in [machine image pipelines](http://www.onegeek.com.au/articles/machine-factories-part1-vagrant), such as a 'Base' and 'Application' images. The example below follows this pattern.

  ### Vagrant Boxes

  Run the ISO builder to produce a simple Base box with VirtualBox guest additions and optionally Windows updates (Uncomment the [relevant](/answer_files/2012_r2/Autounattend.xml#L243-L267) lines in the Autounattend.xml files to enable this):

  ```
  packer build -only=virtualbox-windows-iso 2012r2-virtualbox.json
  ```

  Run the OVF builder to produce a simple base box with Microsoft.Net 4.5.2 and Windows Management Framework 5 Preview installed:
  
  ```
  packer build -only=virtualbox-windows-ovf 2012r2-virtualbox.json
  ```
