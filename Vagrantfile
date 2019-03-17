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

  config.vm.hostname = "mediaserver-dev"

  config.vm.provision :shell, inline: bootstrap

  config.vm.network :private_network, ip: "10.0.1.10"

  # Note the 'ansible.tags' in the provision block.
  # This is probably a better way. Note that this won't work
  # with my vagrant aliases.
  # ANSIBLE_ARGS='--tags "tag1,tag2,..."' vagrant ...

  config.vm.provision :ansible do |ansible|
    # ansible.verbose = "vvv"
    # ansible.raw_arguments = ['--check']
    ansible.raw_arguments = Shellwords.shellsplit(ENV["ANSIBLE_ARGS"]) if ENV["ANSIBLE_ARGS"]

    # ansible.tags = ['configure_snapraid']
    # ansible.tags = ['mergerfs_mount']
    # ansible.tags = ['samba']
    # ansible.tags = ['users']
    # ansible.tags = ['files']

    ansible.compatibility_mode = "2.0"
    ansible.playbook = "playbook.yml"
    ansible.extra_vars = "@vagrant/mediaserver-dev.yml"
  end
end
