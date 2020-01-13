#! /bin/bash

THIS_SCRIPT_PATH=$(readlink -f "$0")
THIS_SCRIPT_DIR=$(dirname ${THIS_SCRIPT_PATH})
SYNCPACK_SETUP_BASH=${THIS_SCRIPT_DIR}/syncpack-setup.bash
SYNCPACK_UTILS_BASH=${THIS_SCRIPT_DIR}/syncpack-utils.bash
WORKSPACE_DIR=${PWD}

source ${SYNCPACK_UTILS_BASH}
if [ $? -ne 0 ]
then
	exit -1
fi

function usage
{
	echo "syncpack usage:"
	echo "  syncpack [COMMAND] [COMMAND ARGS]"
	echo "  Exported Commands:"
	echo "   - init: alias as init_workspace"
	echo "   - sync: alias as sync_file"
	echo "   - version"
}


if [ $# == 0 ]
then
	usage
	exit 0
fi

sync_command=$1
sync_command_args=($*)
sync_command_args=${sync_command_args[*]:1}


if test ${sync_command} = "init"
then
	init_workspace ${sync_command_args}

elif test ${sync_command} = "sync"
then
	sync_workspace

elif [ ${sync_command} == "make_rootfs" ]
then
	make_rootfs ${sync_command_args}

elif [ ${sync_command} == "version" ]
then
	version
else
	echo "!!!!error!!!!! unknown command $1"
	usage
	exit -1
fi

