#!/bin/bash 
SDK_ROOT_DIR=/home/xiachengshun
ENV_PREFIX="export GCDA_MONITOR=1
export TF_POPLAR_FLAGS='--executable_cache_path=/__user_home__/cachedir'
export TMPDIR='/__user_home__/tmp'"

function usage() 
{
	printf "%s usage:\n" $0
	printf "%s sdk_tarball_path\n" $0
	printf "%s "
	exit 1
}

function success_or_die()
{
	_msg=$1
	if [ $? -ne 0 ];then
		printf "%s\n" _msg
		exit 1
	fi
}

function file_not_exist()
{
	_file=$1
	if [ ! -d $_file ];then
		printf "%s is not file or file does not exist\n" $_file
		exit 1
	fi	
}

function dir_not_exist()
{
	_dir=$1
	if [ ! -d $_dir ];then
		printf "%s is not dir or dir does not exist\n" $_dir 
		exit 1
	fi	
}

function file_already_exist()
{
	_file=$1
	if [ -d $_file ];then
		printf "file %s already exist\n" $_file 
		exit 1
	fi	
}

function dir_already_exist()
{
	_dir=$1
	if [ -d $_dir ];then
		printf "dir %s already exist\n" $_dir 
		exit 1
	fi	
}

function mkdir_or_die()
{
	_dir=$1
	mkdir -p $_dir
	success_or_die "create virtualenv failed ${_dir}"
}

function rmdir_or_die()
{
	_dir=$1
	if [ -d $_dir ];then
		rm -rf $_dir
		success_or_die "cann't rm -rf ${_dir}"
	elif [ -f $_dir ];then
		printf "%s is a regular file\n" %{_dir}
	fi  
}

function rm_file_or_die()
{
	_file=$1
	if [ -f $_file ];then
		rm -rf ${_file}
		success_or_die "cann't rm -rf ${_file}"
	elif [ -d $_file ];then
		printf "%s is a regular file\n" %{_file}
	fi  
}

function check_os_match()
{
	_tarball=$1
	local tarball_os_version
	local os_release
	if echo $_tarball | grep centos -i 2>&1 >/dev/null;then
	  tarball_os_version="centos"
	elif echo $_tarball | grep ubuntu -i 2>&1 >/dev/null;then
	  tarball_os_version="ubuntu"
	else
	  tarball_os_version="unknown"
	fi

	if cat /etc/*-release | grep centos -i 2>&1 >/dev/null;then
	  os_release="centos"
	elif cat /etc/*-release | grep ubuntu -i 2>&1 >/dev/null;then
	  os_release="ubuntu"
	else
	  os_release="unknown"
	fi
	if [ $tarball_os_version != $os_release ];then
	  printf "tarball release :%s don't matach os_release: %s\n" "$tarball_os_version" "$os_release"
	  printf "please check\n"
	  exit 1
	fi
}

function create_virtenv()
{
 	_root_dir=$1
	_sdk_version=$2
	dir_not_exist $_dir
	_dir=${_root_dir}/virtenv/${_sdk_version}
	if cat /etc/*-release | grep CentOS -i 2>&1 >/dev/null ; then
	  _dir=${_dir}_centos
	fi
	rmdir_or_die ${_dir}
	mkdir_or_die ${_dir}
	virtualenv_cmd="virtualenv"
	if cat /etc/*-release | grep centos -i 2>&1 >/dev/null;then
	  virtualenv_cmd="virtualenv-3"
	fi
	${virtualenv_cmd} -p /usr/bin/python3 ${_dir}
	success_or_die "create virtualenv failed"
}

function untar_sdk()
{
	tarball=$1
	_root_dir=$2
	dir_not_exist $_dir
	_dir=${_root_dir}/sdk/
	mkdir_or_die ${_dir}
	tar zxvf $tarball -C $_dir
	success_or_die "untar the sdk failed"
}

function create_sdk_envs()
{
	_root_dir=$1
	_sdk_version=$2
	_sdk_dir=$3
	dir_not_exist $_root_dir
	_dir=${_root_dir}/cfgs
	mkdir_or_die ${_dir}
	if cat /etc/*-release | grep CentOS -i 2>&1 >/dev/null ; then
	  _sdk_version=${_sdk_version}_centos
	fi
	_file=${_dir}/gc.env.sdk.${_sdk_version}
	rm_file_or_die ${_file}
	touch ${_file}

	cat >> ${_file} <<EOF
$ENV_PREFIX
EOF

	echo "source ${_root_dir}/virtenv/${_sdk_version}/bin/activate "	>> ${_file}

	for file in $(find ${_root_dir}/sdk/${_sdk_dir} -name "enable.sh" );do
		echo "source  $file"
	done >> ${_file}

	sed -i "s#__user_home__#${SDK_ROOT_DIR}#" ${_file}
	mkdir -p $(cat ${_file} | grep TMPDIR | cut -d '=' -f 2 | tr -d "'")
	mkdir -p $(cat ${_file} | grep TF_POPLAR_FLAGS | cut -d '=' -f 3 | tr -d "'")
	printf "Please source ${_file} to start\n" %{_file}
}

if [ $# -ne 1 ];then
   usage  
fi

tarball=$1
if [ ! -f $tarball ] ;then
	printf "the tarball you specifiy does not exist,please check"
	usage
fi

_tarball_name=$(basename $tarball)
_sdk_dir=$(tar ztf $_tarball_name | head -1)
_sdk_version=$(echo $_tarball_name | awk -F '-' '{printf ("%s-%s",$3,$4)}' | sed 's#.tar.gz##')

check_os_match $tarball

#untar the sdk
untar_sdk $tarball $SDK_ROOT_DIR

#create virtualenv
create_virtenv $SDK_ROOT_DIR $_sdk_version

#create cfgs file 
create_sdk_envs $SDK_ROOT_DIR $_sdk_version $_sdk_dir
