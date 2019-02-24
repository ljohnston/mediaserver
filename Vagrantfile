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

   #
   # We'd like to use the ubuntu image here. Unfortunately, VirtualBox 6 has
   # an issue with adding storage controllers. See here for more:
   #
   #   https://github.com/hashicorp/vagrant/issues/10578
   #
   # For now we'll use the bento image and keep an eye on the issue.
   #

   # config.vm.box = "ubuntu/xenial64"
   config.vm.box = "bento/ubuntu-16.04"

   parityDisk = './.vm/parityDisk.vdi'
   dataDisk1  = './.vm/dataDisk1.vdi'
   dataDisk2  = './.vm/dataDisk2.vdi'

   config.vm.provider :virtualbox do |vb|
       vb.name = "mediaserver-dev"
       vb.memory = 2048
       vb.cpus = 2

       if not File.exists?(parityDisk)
           vb.customize ['createhd', '--filename', parityDisk, '--variant', 'Fixed', '--size', 3 * 1024]
       end

       if not File.exists?(dataDisk1)
           vb.customize ['createhd', '--filename', dataDisk1, '--variant', 'Fixed', '--size', 3 * 1024]
       end

       if not File.exists?(dataDisk2)
           vb.customize ['createhd', '--filename', dataDisk2, '--variant', 'Fixed', '--size', 3 * 1024]
       end

       if ! `VBoxManage showvminfo #{vb.name}`.split("\n").include?(/Storage Controller Name.*SCSI$/)
           vb.customize ['storagectl', :id, '--name', 'SCSI', '--add', 'scsi']
       end

       vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 0, '--device', 0, '--type', 'hdd', '--medium', parityDisk]
       vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', dataDisk1]
       vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', dataDisk2]
   end

   config.vm.provision :shell, inline: bootstrap

   config.vm.hostname = "mediaserver-dev"
   config.vm.define "#{config.vm.hostname}"

   # Note the 'ansible.tags' in the provision block.
   # This is probably a better way. Note that this won't work
   # with my vagrant aliases.
   # ANSIBLE_ARGS='--tags "tag1,tag2,..."' vagrant ...

   config.vm.provision :ansible do |ansible|
       # ansible.verbose = "vvv"
       ansible.tags = ['configure']
       ansible.compatibility_mode = "2.0"
       ansible.playbook = "playbook.yml"
       ansible.extra_vars = "@vagrant/mediaserver-dev.yml"
   end
end
