# mediaserver

Ansible project to configure my media server.

My media server is pretty much based on these links (started with the 2016
link, the second link came along after I'd already gotten something built):

    * https://www.linuxserver.io/2016/02/02/the-perfect-media-server-2016/
    * https://www.linuxserver.io/2017/06/24/the-perfect-media-server-2017/

This ansible config inspired by the following repository from the author of
both of the above links:

https://github.com/IronicBadger/ansible

Here's another good ansible/vagrant with snapraid and mergerfs link:

    * http://zacklalanne.me/using-vagrant-to-virtualize-multiple-hard-drives/   

My inital build was done by hand just because I was (stupidly) in a hurry (why?
I don't know...). This project is an effort to fix that.

This project includes a Vagrantfile for local development. Simply...

    $ vagrant up

    Or, if vm already exists...

    $ vagrant provision

