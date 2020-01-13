#!/bin/bash

THIS_SCRIPT_PATH=$(readlink -f "$0")
THIS_SCRIPT_DIR=$(dirname ${THIS_SCRIPT_PATH})
SYNCPACK_SETUP_BASH=${THIS_SCRIPT_DIR}/syncpack-setup.bash
SYNCPACK_DEPS_PARSER=${THIS_SCRIPT_DIR}/syncpack-deps-parser.bash


source ${SYNCPACK_SETUP_BASH}

SYNC_LIST_DIR_NAME=synclists
SYNC_DIR=${WORKSPACE_DIR}/.sync
SYNC_LIST_DIR=${SYNC_DIR}/synclists
PACK_TMP_PATH=${SYNC_DIR}/packages
PACK_PATH=${WORKSPACE_DIR}


function prepare_packages
{
	if [ -d ${PACK_TMP_PATH} ]
	then
		echo "packages temporary directory exists"
	else
		mkdir -p ${PACK_TMP_PATH}
	fi
}

function init_workspace_usage
{
	echo "init_workspace usage:"
	echo "   init_workspace [url] [branch] [script]: init workspace with git url"
	echo "         - url: workspace script git url."
	echo "         - branch: git branch of workspace sync script."
	echo "         - script: script file name of workspace sync script."
}


function init_workspace
{
	if [ $# != 3 ]
	then
		echo "wrong using of init_workspace $*"
		init_workspace_usage
		exit -1
	fi

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



function sync_file
{
	remote_file_path=$1
	local_path=$2
	
	IS_DIFF=$(rsync -acn --out-format="%n" -e "ssh -p ${RELEASE_SERVER_SSH_PORT}" ${remote_file_path} ${local_path})

	if [ -z "${IS_DIFF}" ]
	then
		return 0
	else
		echo "updating ${remote_file_path} ..."
		rsync -av --progress -e "ssh -p ${RELEASE_SERVER_SSH_PORT}" ${remote_file_path} ${local_path}

		return 1
	fi


	if [ $? -ne 0 ]
	then
		return -1
	fi
}

function parse_depends_script_usage
{
	echo "parse_depends_script usage:"
	echo "    parse_depends_script [script] [readonly] [mode] [prefix]"
}

function parse_depends_script
{
	if [ $# -ne 4 ]
	then
		echo "wrong using of parse_depends_script $*"
		parse_depends_script_usage
		exit -1
	fi

	depends_script=$1
	pack_readonly=$2
	pack_mode=$3
	pack_prefix=$4
	
	cat ${depends_script} | xargs -I {} $0 make_rootfs {} ${pack_readonly} ${pack_mode} ${pack_prefix}
	
}


function update_depends_usage
{
	echo "update_depends usage:"
	echo "    update_depends [arch] [pack] [version] [readonly] [mode] [prefix]" 
	echo "        -mode: mix or iso. In mix mode, all packages installed to same "
	echo "               directory where prefix indicated;"
	echo "               In iso mode, the 'prefix' directory would be seemed as base path, "
        echo "               and each package will installed seperated at the base of base path"
}

function update_depends
{
	if [ $# -ne 6 ]
	then
		echo "wrong using of update_depends $*"
		update_depends_usage
		exit -1
	fi

        pack_arch=$1
        pack_name=$2
        pack_version=$3
	is_read_only=$4
	pack_mode=$5
	pack_prefix=$6

	depends_script_full_name=${pack_name}-${pack_version}_${pack_arch}-depends.bash
	depends_check_path=${RELEASE_SERVER_DEPENDS_ROOT}/${RELEASE_SERVER_TARGET_PLATFORM}/${pack_name}/${pack_version}
	depends_script_path=${DEPENDS_PATH}/${pack_name}/${pack_version}
	

	#echo if ssh -p ${RELEASE_SERVER_SSH_PORT} ${RELEASE_SERVER_USER}@${RELEASE_SERVER_HOST} test -e ${depends_script_path}/${depends_script_full_name}
	if ssh -p ${RELEASE_SERVER_SSH_PORT} ${RELEASE_SERVER_USER}@${RELEASE_SERVER_HOST} test -e ${depends_check_path}/${depends_script_full_name}
	then
		#echo "exist"
		sync_file ${depends_script_path}/${depends_script_full_name} ${PACK_TMP_PATH}
		sync_file_rsl=$?

		if [ ${sync_file_rsl} -lt 0 ]
		then
			return -1
		fi

		echo "sync ${pack_name} depends..."
		parse_depends_script ${PACK_TMP_PATH}/${depends_script_full_name} ${is_read_only} ${pack_mode} ${pack_prefix}

	else
		#echo "${depends_script_full_name} not exist"
		#echo "check dir ${depends_script_path}"
		if ssh -p ${RELEASE_SERVER_SSH_PORT} ${RELEASE_SERVER_USER}@${RELEASE_SERVER_HOST} test -d ${depends_check_path}
		then
			echo "warning: depends directory exist but no depends script."
		fi
	fi
}

function update_package_usage
{
	echo "update_package usage:"
	echo "    update_package [arch] [package] [version] [prefix]"
}

function update_package
{
	if [ $# -ne 4 ]
	then
		echo "wrong using of update_package $*"
		update_package_usage
		exit -1;
	fi
        pack_arch=$1
        pack_name=$2
        pack_version=$3
	pack_prefix=$4

	make_rootfs ${pack_arch} ${pack_name} ${pack_version} true iso ${pack_prefix}
}

function make_rootfs_usage
{
	echo "make_rootfs usage:"
	echo "    make_rootfs [arch] [pack] [version] [readonly] [mode] [prefix]"
	echo "        [arch]: architecher of target package"
	echo "        [pack]: package name"
	echo "        [version]: package version"
	echo "        [prefix]: installation position relevated to targe rootfs"
	echo "        [readonly]: true or false, change access permision of package to read only"
	echo "        [mode]: iso or mix, change access permision of package to read only"

	echo "make_rootfs example:"
	echo "    make_rootfs arm64 boost 1.58.0 boost true"
	echo ""
	echo "    after run, the boost package would be installed to"
	echo "    \${PWD}/package/boost, and the access permision will "
	echo "    be changed to readonly"
}

function make_rootfs
{
	if [ $# -ne 6 ]
	then
		echo "wrong using of make_rootfs_usage $*"
		make_rootfs_usage
		exit -1;
	fi

        pack_arch=$1
        pack_name=$2
        pack_version=$3
	is_read_only=$4
	pack_mode=$5
	pack_prefix=$6
        pack_full_name=${pack_name}-${pack_version}_${pack_arch}.tar.gz
	need_update="false"


	if [ ${pack_mode} == "iso" ]
	then
		install_path=${pack_prefix}/${pack_name}
	elif [ ${pack_mode} == "mix" ]
	then
		install_path=${pack_prefix}
	else
		echo "wrong using of parse_depends_script $*"
		parse_depends_script_usage
		exit -2
	fi

	sync_file ${RELEASE_PATH}/${pack_name}/${pack_version}/${pack_full_name} ${PACK_TMP_PATH}

	sync_file_rsl=$?

	if [ -d ${PACK_PATH}/${install_path} ]
	then 
		chmod u+w ${PACK_PATH}/${install_path}
		
	fi
	
	if [ ${sync_file_rsl} == 1 ]
	then

		if [ -d ${PACK_PATH}/${install_path} ]
		then
			rm -rf ${PACK_PATH}/${install_path}
		fi

	elif [ ${sync_file_rsl} == 0 ]
	then
		echo "${pack_full_name} is up to date."

	else
		echo "get package error occured!"
		echo "    please check package name/version/arch is right."
		exit -1
	fi

	if [ ! -d ${PACK_PATH}/${install_path} ]
	then
		mkdir -p ${PACK_PATH}/${install_path}
		need_update="true"
	fi

	if [ ${pack_mode} == "mix" ]
	then
		need_update="true"
	fi

	if [ "${need_update}" == "true" ]
	then
		tar -xvzf ${PACK_TMP_PATH}/${pack_full_name} -C ${PACK_PATH}/${install_path}

		if [ $? -ne 0 ]
		then
			echo "decompress packages faileld!"
			exit -2
		fi

		if [ "${is_read_only}" == "true" ]
		then
			chmod u-w ${PACK_PATH}/${install_path}
			if [ $? -ne 0 ]
			then
				echo "change mode of package failed!"
				exit -4
			fi
		elif [ "${is_read_only}" == "false" ]
		then
			echo "" > /dev/null
		else
			echo "wrong using of make_sysroot_usage $*"
			make_sysroot_usage
			exit -3
		fi
	fi

	update_depends ${pack_arch} ${pack_name} ${pack_version} ${is_read_only} ${pack_mode} ${pack_prefix}

	if [ $? -ne 0 ]
	then
		echo "update sync error occured, please check package depends."
		exit -4
	fi
}

