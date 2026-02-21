# TODO:

  - Address all ansible deprecation warnings.

# mediaserver

Ansible project to configure my media server.

My media server is pretty much based on these links (started with the 2016
link, the second link came along after I'd already gotten something built):

    * https://www.linuxserver.io/2016/02/02/the-perfect-media-server-2016/
    * https://www.linuxserver.io/2017/06/24/the-perfect-media-server-2017/

This ansible config inspired by the following repository from the author of
both of the above links:

    * https://github.com/IronicBadger/ansible

## Prerequisites

- ansible
- terraform
- ansible galaxy roles

  This project uses roles from ansible galaxy that need to be installed prior
  to running any ansible configuration commands:

    $ ansible-galaxy install --role-file requirements.yml --roles-path roles.galaxy

## Ansible 

The ansible config supports two mediaserver environments, 'dev' and 'prd'. The
dev environment exists in Oracle Cloud Infrastructure and the project includes
terraform configuration to manage the dev infrastructure.

The ansible configuration uses ansible-vault to manage secrets.

## Make

The project includes a Makefile to manage all of the infrastructure creation
and configuration tasks and more. To get a full list of supported targets run:

    $ make

Some important targets:

  - `dev-infra`: Run the terraform to build the dev infrastructure in OCI.

  - `dev-config`: Apply ansible configuration to the dev mediaserver running
    in OCI.

  - `dev-test`: Run some tests to validate the mediaserver configuration in
    dev.

  - `dev`: Run all of the above `dev-...` tasks in order.

  - `dev-destroy`: Run the terraform to destroy the dev infrastructure running
    in OCI.

  - `prd-config`: Apply ansible configuration to the prd mediaserver.

  - `prd-test`: Run some tests to validate the mediaserver configuration in
    prd.

  - `prd`: Run the above `prd-...` tasks in order.

  - `macbook-config`: There is ansible configuration for a local macbook to
    automate local mounts of mediaserver data directory.

Any of the above `...-config` targets run ansible configurations. The Makefile
supports injection of ansible arguments via the `ANSIBLE_ARGS` environment
variable. For example:

    $ ANSIBLE_ARGS='-v' make dev-config
    $ ANSIBLE_ARGS='--tags=mediaserver_test' make dev-config
    $ ANSIBLE_ARGS='-v --tags=mediaserver_test' make dev-config
    $ ANSIBLE_ARGS='--check' make prd-config

## iTunes

All of the music media on the mediaserver is managed via iTunes. The iTunes
library location on my local macbook is configured to live on the mediaserver
(this is why the macbook ansible config for local mediaserver mounts is
important). To add new music to the prd mediaserver, simply import it into
iTunes.

**NOTE**: I'm not sure if the following is still relevant to the new Apple Music
app.

Note that iTunes can be a pain in the ass when it comes to how it manages
libraries and such. It's possible that it can get out of sync with the
filesystem. We can audit things via the following:

  - Export albums from iTunes Library XML file
    ```
    $ grep '>Album<' iTunes\ Library.xml \
        |sed 's/.*<string>\(.*\)<\/string>/\1/g' \
        |sort -u >albums_xml
    ``````

  - Export albums from iTunes directory
    ```
    $ find iTunes\ Media/Music/ -type f -name '*.m4a' \
        |sed -r 's|/[^/]+$||' \
        |awk -F "/" '{print $NF}' \
        |sort -u >albums_fs
    ```

  - Inspect/diff the two files created above.
