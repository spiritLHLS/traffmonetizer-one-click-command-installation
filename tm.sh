#!/bin/bash
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && exit 1

read -p "Enter your token, something end with ==, if you do not find it, open https://traffmonetizer.com/?aff=96902: " TMTOKEN 
eval "echo $TMTOKEN > .env"

ARCH=$(uname -m)
case "$ARCH" in
aarch64 ) ARCHITECTURE="arm64";;
x86_64 ) ARCHITECTURE="amd64";;
* ) ARCHITECTURE="amd64";;
esac

if [ $SYSTEM = "CentOS" ]; then
    yum install -y sudo
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    docker rm -f tm >/dev/null 2>&1
    if [ $ARCHITECTURE = "amd64" ]; then
        docker pull traffmonetizer/cli:latest
    else
        docker pull traffmonetizer/cli:arm64v8
    fi
    docker run -d --name tm traffmonetizer/cli start accept --token "$TMTOKEN"
else
    docker rm -f tm >/dev/null 2>&1
    apt -y install docker.io
    docker pull traffmonetizer/cli:latest
    docker run -d --name tm traffmonetizer/cli start accept --token "$TMTOKEN"
fi