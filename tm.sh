#!/bin/bash
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|amazon linux|alma|rocky")
RELEASE=("Debian" "Ubuntu" "CentOS")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && break
done

[[ -z $SYSTEM ]] && exit 1

read -p "Enter your token, something end with =, if you do not find it, open https://traffmonetizer.com/?aff=96902: " TMTOKEN 
eval "echo $TMTOKEN > .env"

ARCH=$(uname -m)
case "$ARCH" in
aarch64 ) ARCHITECTURE="arm64v8";;
x64|x86_64|amd64 ) ARCHITECTURE="latest";;
* )  echo -e "ERROR: Unsupported architecture: $ARCH\n" && exit 1;;
esac

if [ $SYSTEM = "CentOS" ]; then
    ${PACKAGE_INSTALL[int]} yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    ! systemctl is-active docker >/dev/null 2>&1 && echo -e " \n Install docker \n " && ${PACKAGE_INSTALL[int]} docker-ce docker-ce-cli containerd.io
    systemctl enable --now docker
else
    ! systemctl is-active docker >/dev/null 2>&1 && echo -e " \n Install docker \n " && ${PACKAGE_INSTALL[int]} docker.io
fi

docker rm -f tm >/dev/null 2>&1
docker run -d --name tm traffmonetizer/cli:$ARCHITECTURE start accept --token "$TMTOKEN"
docker run -d --name watchtower --restart always  -p 2095:8080 -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup
