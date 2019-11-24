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

  # Set hostname variable here so we can use it in the 'VBoxManage' command
  # below as 'vb.name' isn't directly accessible there.
  hostname = 'mediaserver-dev'

  config.vm.provider :virtualbox do |vb|

    # Controls how the vm shows up in the VirtualBox GUI and comand line.
    vb.name = hostname

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

    # On the first 'up', the vm won't exist and this shell command will
    # complain. Regardless, if we just redirect stderr we won't see any errors
    # and the find will work as exepected.
    if ! `VBoxManage showvminfo #{hostname} 2>&1`.split("\n").find { |l| l =~ /Storage Controller Name.*SCSI$/ }
      vb.customize ['storagectl', :id, '--name', 'SCSI', '--add', 'scsi']
    end

    vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 0, '--device', 0, '--type', 'hdd', '--medium', parityDisk]
    vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', dataDisk1]
    vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', dataDisk2]
  end

  # This is required to set 'ansible.groups' for this vm.
  config.vm.define hostname

  config.vm.hostname = hostname

  config.vm.provision :shell, inline: bootstrap

  config.vm.network :private_network, ip: "10.0.1.10"

  # config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./test", "/test"

  config.vm.provision :ansible do |ansible|
    ansible.compatibility_mode = "2.0"

    ansible.galaxy_role_file = 'requirements.yml'
    ansible.galaxy_roles_path = 'roles.galaxy'
    ansible.galaxy_command = 'ansible-galaxy install --role-file=%{role_file} --roles-path=%{roles_path}'

    ansible.raw_arguments = Shellwords.shellsplit(ENV["ANSIBLE_ARGS"]) if ENV["ANSIBLE_ARGS"]

    ansible.vault_password_file = '~/.ansible/.vault_pass'

    ansible.groups = {
      "dev" => [hostname],
      "mediaservers" => [hostname],
    }

    ansible.playbook = "playbook.yml"
  end

  config.vm.provision :serverspec do |spec|
    spec.pattern = 'serverspec/*_spec.rb'
  end
end
