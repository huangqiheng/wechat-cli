#!/bin/dash

main () 
{
	setup_nodejs 10
	check_npm_g n ts-node typescript
	npm install
}

setup_nodejs()
{
        if cmd_exists /usr/bin/node; then
                echo "${Green}node has been installed${Color_Off}"
                return
        fi

        version=${1:-'10'}

        curl -sL https://deb.nodesource.com/setup_${version}.x | sudo -E bash -
        check_apt nodejs
}

init_colors()
{
        [ ! -z $Color_Off ] && return
        Color_Off='\033[0m'       # Text Reset
        Red='\033[0;31m'          # Red
        Green='\033[0;32m'        # Green
        Yellow='\033[0;33m'       # Yellow
        Blue='\033[0;34m'         # Blue
}; init_colors;

repo_update()
{
	GIT_PUSH_DEFAULT=simple

	#---------------------------------------------------------------------
	# pull

	THIS_DIR=`dirname $(readlink -f $0)`

	cd $THIS_DIR
	IFS=; pull_result=$(git pull)

	if echo $pull_result | grep -q 'insufficient permission for adding an object'; then
		sudo chown -R $(id -u):$(id -g) "$(git rev-parse --show-toplevel)/.git"
	fi

	if echo $pull_result | grep -q 'use "git push" to publish your local commits'; then
		git push
		exit
	fi

	echo ${Green}${pull_result}${Color_Off}

	#---------------------------------------------------------------------
	# config


	user=$(git config --global --get user.name)
	if [ -z $user ]; then
		[ -z $GIT_USER_NAME ] && read -p 'Input your name: ' GIT_USER_NAME
		git config --global --add user.name $GIT_USER_NAME
	fi

	email=$(git config --global --get user.email)
	if [ -z $email ]; then
		[ -z $GIT_USER_EMAIL ] && read -p 'Input your email: ' GIT_USER_EMAIL
	       	git config --global --add user.email $GIT_USER_EMAIL
	fi

	push=$(git config --global --get push.default)
	if [ -z $push ]; then
		[ -z $GIT_PUSH_DEFAULT ] && read -p 'Input push branch( simple/matching ): ' GIT_PUSH_DEFAULT
		git config --global --add push.default $GIT_PUSH_DEFAULT
	fi

	gituser=$(git config --global --get user.gituser)
	if [ -z $gituser ]; then
		[ -z $GIT_PUSH_USER ] && read -p 'Input your GitHub username: ' GIT_PUSH_USER
		[ -z $GIT_PUSH_USER ] && exit 1
	       	git config --global --add user.gituser $GIT_PUSH_USER
		gituser=$GIT_PUSH_USER
	fi

	push_url=$(git remote get-url --push origin)

	if ! echo $push_url | grep -q "${gituser}@"; then
		new_url=$(echo $push_url | sed -e "s/\/\//\/\/${gituser}@/g")
		git remote set-url origin $new_url
		echo "${Green}Update remote url: $new_url.${Color_Off}"
	fi

	#---------------------------------------------------------------------
	# push

	input_msg=$1
	input_msg=${input_msg:="update"}

	cd $THIS_DIR
	git add .
	IFS=; commit_result=$(git commit -m "${input_msg}")

	if echo $commit_result | grep -q 'nothing to commit'; then
		echo "${Green}Nothing to commit.${Color_Off}"
		exit
	fi

	echo ${Green}${commit_result}${Color_Off}

	git config --global credential.helper 'cache --timeout 21600'
	git push
}

check_sudo()
{
	if [ $(whoami) != 'root' ]; then
	    echo "This script should be executed as root or with sudo:"
	    echo "	${Red}sudo sh $ORIARGS ${Color_Off}"
	    exit 1
	fi
}

check_apt()
{
        for package in "$@"; do
                if apt_exists $package; then
			echo "${Green}${package} has been installed.${Color_Off}"
                else
                        apt install -y "$package"
                fi
        done
}

check_npm_g()
{
        if cmd_exists "$1"; then
		echo "${Green}$1 has been installed.${Color_Off}"
        else
                npm install -g "$2"
        fi
}

check_update()
{
	check_sudo

	if [ "$1" = 'f' ]; then
		apt update -y
		apt upgrade -y
		return 0
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))

	local repo_changed=0

	if [ $# -gt 0 ]; then
		for the_param in "$@"; do
			the_ppa=$(echo $the_param | sed 's/ppa:\(.*\)/\1/')

			if [ ! -z $the_ppa ]; then 
				if ! grep -q "^deb .*$the_ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
					add-apt-repository -y $the_param
					repo_changed=1
					break
				else
					echo "${Green}repo ${the_ppa} has already exists.${Color_Off}"
				fi
			fi
		done
	fi 

	if [ $repo_changed -eq 1 ] || [ $diff_time -gt 604800 ]; then
		apt update -y
	fi

	if [ $diff_time -gt 6048000 ]; then
		apt upgrade -y
	fi 
}

apt_exists()
{
	[ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -gt 0 ]
}

cmd_exists() 
{
	type "$(which "$1")" > /dev/null 2>&1
}

maintain()
{
	[ "$1" = 'update' ] && repo_update && exit
	[ "$1" = 'help' ] && show_help_exit $2
	check_update
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
