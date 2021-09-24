Vagrant.require_version ">= 1.6.2"

Vagrant.configure(2) do |config|
    config.vm.define "docker", primary: true do |srv|
        srv.vm.box = "ubuntu/focal64"

        srv.vm.provider :virtualbox do |v, override|
            v.name = "Qlik-Cli-circle"
            v.linked_clone = true
            v.customize ["modifyvm", :id, "--memory", 2048]
            v.customize ["modifyvm", :id, "--cpus", 2]
            v.customize ["modifyvm", :id, "--vram", 64]
            v.customize ["modifyvm", :id, "--clipboard", "disabled"]
            v.customize ["modifyvm", :id, "--chipset", "ich9"]
            v.customize ["modifyvm", :id, "--uartmode1", "file", "serial.txt"]
        end

        srv.vm.hostname = "qlik-cli-docker"

        srv.vm.provision :shell, inline: <<-EOF
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get -y update
            sudo apt-get -y install docker.io python

            sudo addgroup vagrant docker
            sudo addgroup ubuntu docker

            curl -fsSL https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/master/install.sh | sudo bash
EOF
    end
end
