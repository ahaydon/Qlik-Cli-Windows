# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'

if File.exists?(File.expand_path "./config.json")  
    config = JSON.parse(File.read(File.expand_path "./config.json"))
end
servers = config["servers"]

Vagrant.configure(2) do |config|
  require './vagrant-provision-reboot-plugin'

  servers.each do |attr|
    config.vm.define attr["name"] do |srv|
      srv.vm.box = attr["box"]
      srv.vm.communicator = "winrm"
      srv.vm.network "private_network", virtualbox__intnet: true, ip: attr["ip"]
      attr["ports"].each do |port|
        srv.vm.network "forwarded_port", guest: port["guest"], host: port["host"]
      end
      srv.vm.synced_folder "../shared", "/shared"
      srv.vm.hostname = attr["name"]
      srv.vm.provision "file", source: "Qlik-Cli.psm1", destination: "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\Modules\\Qlik-Cli\\Qlik-Cli.psm1"
      srv.vm.provision :shell, path: "provision.ps1"
      srv.vm.provision :windows_reboot
      srv.vm.provision :shell, path: "provision.ps1"
    end
  end
end
