#!/bin/bash

THIS_SCRIPT_PATH=$(readlink -f "$0")
THIS_SCRIPT_DIR=$(dirname ${THIS_SCRIPT_PATH})
SYNCPACK_SETUP_BASH=${THIS_SCRIPT_DIR}/syncpack-setup.bash


source ${SYNCPACK_SETUP_BASH}

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

function update_depends
{
        pack_arch=$1
        pack_name=$2
        pack_version=$3

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
		chmod u+x ${PACK_TMP_PATH}/${depends_script_full_name}
		source ${PACK_TMP_PATH}/${depends_script_full_name}
	else
		#echo "${depends_script_full_name} not exist"
		#echo "check dir ${depends_script_path}"
		if ssh -p ${RELEASE_SERVER_SSH_PORT} ${RELEASE_SERVER_USER}@${RELEASE_SERVER_HOST} test -d ${depends_check_path}
		then
			echo "warning: depends directory exist but no depends script."
		fi
	fi
}


function update_package
{
	if [ $# -ne 3 ]
	then
		echo "usage error update_package [arch] [pack] [version]"
		exit -1;
	fi
        pack_arch=$1
        pack_name=$2
        pack_version=$3
        pack_full_name=${pack_name}-${pack_version}_${pack_arch}.tar.gz

	sync_file ${RELEASE_PATH}/${pack_name}/${pack_version}/${pack_full_name} ${PACK_TMP_PATH}

	sync_file_rsl=$?
	
	if [ ${sync_file_rsl} == 1 ]
	then

		if [ -d ${PACK_PATH}/${pack_name} ]
		then
			chmod a+w ${PACK_PATH}/${pack_name}
			rm -rf ${PACK_PATH}/${pack_name}
		fi

	elif [ ${sync_file_rsl} == 0 ]
	then
		echo "${pack_full_name} is up to date."
	fi

	if [ $? -lt 0 ]
	then
		echo "get package error occured!"
		echo "    please check package name/version/arch is right."
		exit -1
	fi

	if [ ! -d ${PACK_PATH}/${pack_name} ]
	then
		mkdir -p ${PACK_PATH}/${pack_name}
		tar -xvzf ${PACK_TMP_PATH}/${pack_full_name} -C ${PACK_PATH}/${pack_name}

		if [ $? -ne 0 ]
		then
			echo "decompress packages faileld!"
			exit -2
		fi

		chmod a-w ${PACK_PATH}/${pack_name}

		if [ $? -ne 0 ]
		then
			echo "change mode of package failed!"
			exit -3
		fi
	fi

	update_depends ${pack_arch} ${pack_name} ${pack_version}

	if [ $? -ne 0 ]
	then
		echo "update sync error occured, please check package depends."
		exit -4
	fi
}

