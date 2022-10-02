#!/bin/bash

# Description: This script is for installing docker in a based linux work host



# 1 - implement a check to filter out bad conditions
# 2 - check/uninstall old docker version. Thus to explicitly remove the
#   contenent of /var/lib/docker&containared directories
# 3 - proceed to the installation process. But keep in mind that you shall
#   monitor the continually update of docker source code (to be handed)
#
#

check() {
	[[ $1 -eq 0 ]] && echo $2 OK || {
		echo $2 NOK
		exit 1
	}
}

filter() {
	# filter from bottom to up

	local cur_arch=$(uname -a | awk '{print $12}')
	local split1=$(cat /etc/lsb-release | grep CODENAME | cut -d '=' -f2)
	local split2=$(cat /etc/lsb-release | grep RELEASE | cut -d '=' -f2)
	local split3=$(cat /etc/lsb-release | grep DESCRIPTION | cut -d '"' \
		-f2 | cut -d ' ' -f3)

	local cur_sw_version="${split1} ${split2} ${split3}"

	case ${cur_arch} in 
		x86_64|amd64|armhf|arm64|s390)
			echo "architecture is supported for docker install"
			;;
		*)
			echo "architecture is not supported"
			exit 1
			;;
	esac
	
	case ${cur_sw_version} in
		"jammy 22.04 LTS"|"impish 21.10"|"focal 20.04 LTS"|"bionic 18.04 LTS")
			echo "software version is valuable"
			;;
		*)
			echo "software version is not valuable"
			exit 1
			;;
	esac

}

uninstall() {

	# uninstall implicitly and explicitly docker and its dependencies
	sudo apt-get update
	sudo apt-get remove docker docker-engine docker.io containerd runc
	check $? "remove all docker varieties"

	sudo rm -rfv /var/lib/docker
	sudo rm -rfv /var/lib/containerd
	check $? "remove common docker tools"
}

setup() {

	echo "start the setup of docker"
	sudo apt-get update
	
	# install some dependencies
	sudo apt-get install -y ca-certificates curl gnupg lsb-release
	check $? "install package that allow to use repository over HTTPS"

	# add docker official GPG key
	sudo mkdir -p /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg \
		--dearmor -o /etc/apt/keyrings/docker.gpg
	check $? "add docker GPG key"

	sudo chmod a+r /etc/apt/keyrings/docker.gpg

	# setup the repository
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
		https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
		| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

	check $? "setup repository"

	echo "How would you install docker?"
	echo "Please pick up one (1/2) from the below list"
	echo "[1]: Update the apt package index and install last version"
	echo "[2]: Install specific version"
	read -p "Type your choice here:" choice
	
	case ${choice} in
		1)
			sudo apt-get update
			sudo apt-get install -y docker-ce docker-ce-cli \
				containerd.io docker-compose-plugin
			check $? "install docker using apt"
			;;
		2)
			echo "available version list:"
			sudo apt-cache madison docker-ce
			echo "choose a version using the version string from
			the second column"
			read -p "Enter what version you need to install:" \
				version

			[[ "x${version}" = "x" ]] && {
				echo "Bad choice"
				exit 1
			}
			
			# test purpose: display the version variable
			echo "the version: ${version}"

			sudo apt-get install docker-ce=${version} \
				docker-ce-cli=${version} containerd.io docker-compose-plugin

			check $? "install specific docker version"
			;;
		*)
			echo "Unknown choice"
			exit 1
			;;
	esac

	echo "Testing the install of docker"
	sudo docker run hello-world
	# add a check here to exit
}


install_engine() {

	filter
	uninstall
	setup

}

install_engine

# action for post install : call the post install wrapper

. post_install.sh


exit 0
