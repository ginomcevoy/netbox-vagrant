# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.hostname = "netbox-demo"

  config.vm.network :forwarded_port, guest: 80, host: 8080, id: 'http'

  config.vm.synced_folder '.', '/vagrant', disabled: true

#Update VM resources below as needed
  config.vm.provider :virtualbox do |vb|
    vb.name = "Netbox-Demo"
    vb.memory = 2048
    vb.cpus = 1
    vb.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
  end

  config.vm.provision "file", source: "./config_files", destination: "/home/vagrant/config_files"
  config.vm.provision :shell, path: "bootstrap.sh"

end
