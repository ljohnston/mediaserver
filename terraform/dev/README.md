
# terraform

This directory is here to support terraform usage via tf.sh, which is a
wrapper script around terraform that handles environment separation,
workspace managment, etc.

The tf.sh script requires an infrastructure "id" parameter, that simply
specifies a subdirectory that includes addtional `*.tfvar` files for
tf.sh to pass along to the terraform command line.

At the moment, this project only supports a single environment (or
infrastructure id) of 'dev', so no dev-specific variable settings/overrides
are required. So no `tfvar` files here for now.


