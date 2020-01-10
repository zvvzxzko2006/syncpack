#! /bin/bash

THIS_SCRIPT_PATH=$(readlink -f "$0")
THIS_SCRIPT_DIR=$(dirname ${THIS_SCRIPT_PATH})
SYNCPACK_SETUP_BASH=${THIS_SCRIPT_DIR}/syncpack-setup.bash
SYNCPACK_UTILS_BASH=${THIS_SCRIPT_DIR}/syncpack-utils.bash

source ${SYNCPACK_UTILS_BASH}
if [ $? -ne 0 ]
then
	exit -1
fi

function usage
{
	echo "syncpack usage:"
	echo "  syncpack COMMAND [COMMAND ARGS]"
	echo "  example:"
	echo "           syncpack init git@github:example/workspace"
	echo "  COMMAND:"
	echo "   - init [url] [branch] [script]: init workspace with git url"
	echo "         - url: workspace script git url."
	echo "         - branch: git branch of workspace sync script."
	echo "         - script: script file name of workspace sync script."
	echo "   - sync: sync workspace"
}

SYNC_LIST_DIR_NAME=synclists
WORKSPACE_DIR=${PWD}
SYNC_DIR=${WORKSPACE_DIR}/.sync
SYNC_LIST_DIR=${SYNC_DIR}/synclists
PACK_TMP_PATH=${SYNC_DIR}/packages
PACK_PATH=${WORKSPACE_DIR}/packages


function prepare_packages
{
	if [ -d ${PACK_TMP_PATH} ]
	then
		echo "packages temporary directory exists"
	else
		mkdir -p ${PACK_TMP_PATH}
	fi

	if [ -d ${PACK_PATH} ]
	then
		echo "packages directory exists"
	else
		mkdir -p ${PACK_PATH}
	fi
}

function init_workspace
{
	init_git_url=$1
	git_branch=$2
	script_file=$3

	mkdir -p ${SYNC_DIR}
	cd ${SYNC_DIR}
	echo "init with : ${init_git_url}:branch ${git_branch} file ${script_file}"
	echo "git clone ${init_git_url} -b ${git_branch} --single-branch --depth=1 ${SYNC_LIST_DIR_NAME}"
	git clone ${init_git_url} -b ${git_branch} --single-branch --depth=1 ${SYNC_LIST_DIR_NAME}
	ln -sf ${SYNC_LIST_DIR_NAME}/${script_file} syncscript.bash
}

function sync_workspace
{
	echo "start sync workspace.."

	prepare_packages

	source .sync/syncscript.bash
}



if [ $# == 0 ]
then
	usage
	exit 0
fi

sync_command=$1

if test ${sync_command} = "init"
then
	if [ $# != 4 ]
	then 
		usage
		echo "type arguments of init."
		exit 0
	fi

	init_workspace $2 $3 $4
	exit 0
elif test ${sync_command} = "sync"
then
	if [ $# != 1 ]
	then
		usage
		exit 0
	fi

	sync_workspace
	exit 0
fi

