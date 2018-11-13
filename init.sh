#!/bin/dash

main () 
{
	echo ''
}

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
	echo $pull_result

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
	       	git config --global --add user.gituser $GIT_PUSH_USER
	fi

	push_url=$(git remote get-url --push origin)

	if ! echo $push_url | grep -q "${gituser}@"; then
		new_url=$(echo $push_url | sed -e "s/\/\//\/\/${gituser}@/g")
		git remote set-url origin $new_url
		echo "Update remote url: $new_url"
	fi

	#---------------------------------------------------------------------
	# push

	input_msg=$1
	input_msg=${input_msg:="update"}

	cd $THIS_DIR
	git add .
	IFS=; commit_result=$(git commit -m "${input_msg}")

	if echo $commit_result | grep -q 'nothing to commit'; then
		echo 'Nothing to commit.'
		exit
	fi

	echo $commit_result

	git config --global credential.helper 'cache --timeout 21600'
	git push

}



maintain()
{
	check_update
	[ "$1" = 'update' ] && repo_update && exit
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
