# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

#
# Bootstrap script that will be executed only once.
#

bootstrap = <<BOOTSTRAP

test -f /etc/bootstrapped && exit

echo "alias ll='ls -la'" >> .bashrc
echo 'set -o vi' >> .bashrc

date > /etc/bootstrapped

BOOTSTRAP

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

   # ubuntu 16.04
   config.vm.box = "ubuntu/xenial64"

   config.vm.provider :virtualbox do |v|
     v.name = "mediaserver.dev"
     v.memory = 2048
     v.cpus = 2
   end

   # Port forwards.
   #config.vm.network "forwarded_port", guest: 8080, host: 8080

   # Synced folders.
   #config.vm.synced_folder "../some-folder", "/tmp/some-folder"

   config.vm.provision :shell, inline: bootstrap

   config.vm.provision :ansible do |ansible|
     # ansible.verbose = "vvv"
     ansible.compatibility_mode = "2.0"
     ansible.playbook = "main.yml"
   end

end
