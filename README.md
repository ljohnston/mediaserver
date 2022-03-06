# TODO:

    x data disk/mount
    x Alison's laptop backup
    x snapraid sync script
    - backups (backblaze)
    - mediaserver scripts
    - photo libraries/handling
    - Nextcloud

# mediaserver

Ansible project to configure my media server.

My media server is pretty much based on these links (started with the 2016
link, the second link came along after I'd already gotten something built):

    * https://www.linuxserver.io/2016/02/02/the-perfect-media-server-2016/
    * https://www.linuxserver.io/2017/06/24/the-perfect-media-server-2017/

This ansible config inspired by the following repository from the author of
both of the above links:

    * https://github.com/IronicBadger/ansible

Here's another good ansible/vagrant with snapraid and mergerfs link:

    * http://zacklalanne.me/using-vagrant-to-virtualize-multiple-hard-drives/   

##  Ansible 

This project uses some roles from ansible galaxy. To install them:

    $ ansible-galaxy install --role-file requirements.yml --roles-path roles.galaxy

##  Vagrant

This project includes a Vagrantfile for local development. Simply...

    $ vagrant up

  Or, if vm already exists...

    $ vagrant provision

  Or, to target specfic ansible configuration:

    ANSILBE_ARGS='--tags snapraid' vagrant provision

### Vagrant guest additions plugin

  The vagrant guest addtions plugin should be installed (no configuration
  should be necessary though).

    $ vagrant plugin install vagrant-vbguest

## mediaserver

To use this project to provision the "production" mediaserver, simply:

    $ ansible-playbook playbook.yml --vault-id ~/.ansible/.vault_pass -i inventory/hosts

## iTunes

iTunes is a pain in the ass when it comes to how it manages libraries and such.
It's possible that it can get out of sync with the filesystem.

We can audit things via the following:

  iTunes Library
    $ grep '>Album<' iTunes\ Library.xml |sed 's/.*<string>\(.*\)<\/string>/\1/g' |sort -u >albums_xml

  File System
    $ find iTunes\ Media/Music/ -type f -name '*.m4a' |sed -r 's|/[^/]+$||' |awk -F "/" '{print $NF}' |sort -u >albums_fs

  diff away ...
