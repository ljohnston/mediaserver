#!/usr/bin/env bash

tf_var_file_cmds=(
    'apply'
    'destroy'
    'import'
    'plan'
    'refresh'
    'validate'
    )

tf_workspace_cmds=(
    "${tf_var_file_cmds[@]}"
    'console'
    'graph'
    'output'
    'show'
    'state'
    'taint'
    'untaint'
    )

tf_passthrough_cmds=(
    'get'
    'init'
    'workspace'
    )

die() {
    echo -e >&2 "$@"
    exit 1
}

msg() {
    echo -e >&2 "$@"
}

function usage() {
    if [ -n "$1" ]; then echo -e >&2 "$1"; fi
    die "Usage: ${0} <infrastructure_id> <terraform_command> [<command_args>]"
}

function set_workspace() {
    if ! terraform workspace list |grep -q "^[* ]\s*${infrastructure_id}\s*$"; then
        # Workspace doesn't exist... create it (also selects it).
        terraform workspace new ${infrastructure_id}
    elif ! terraform workspace list |grep -q "^\*\s*${infrastructure_id}\s*$"; then
        # Workspace exists, but it's not current... select it.
        terraform workspace select ${infrastructure_id}
    fi
}

function build_command() {
    local tf_cmd=$1
    local tf_cmd_args=${@:2}

    cmd="terraform ${tf_cmd}"

    if [[ ${tf_var_file_cmds[*]} =~ ${tf_cmd} ]] ; then
        for f in $(ls ${infrastructure_id}/*.tfvars 2>/dev/null); do
            cmd="${cmd} -var-file=${f}"
        done
    fi

    cmd="${cmd} ${tf_cmd_args}"

    echo $cmd
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [[ -n "${1}" && ${tf_passthrough_cmds[*]} =~ ${1} ]] ; then
    tf_cmd=${1}
    tf_cmd_args=${@:2}
else
    [ $# -ge 2 ] || usage

    infrastructure_id=${1}
    tf_cmd=${2}
    tf_cmd_args=${@:3}

    if [[ ! -d ${script_dir}/${infrastructure_id} ]]; then
        die "Infrastructure subdir '${infrastructure_id}' not found."
    fi
fi

# Export some possibly useful TF_VAR_'s.
export TF_VAR_infrastructure_id=${infrastructure_id}
export TF_VAR_home=${HOME}

# Export TF_VAR_'s for anything being set in ~/.oci/config.
# Any vars also specified within the project will take precedence.
[ -f ${script_dir}/env_vars ] && eval $(OCI_CLI_PROFILE=${OCI_CLI_PROFILE} ${script_dir}/env_vars)

cmd=$(build_command $tf_cmd $tf_cmd_args)
if [ -n "$TF_DEBUG" ]; then
  echo "[DEBUG] cmd=${cmd}"
  echo
  echo "[DEBUG] --- env:start --------------------------------------"
  env
  echo "[DEBUG] --- env:end ----------------------------------------"
  echo
fi

if [[ ${tf_workspace_cmds[*]} =~ ${tf_cmd} ]] ; then
    set_workspace
fi

eval ${cmd}
