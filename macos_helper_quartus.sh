#!/bin/bash

ACCOUNT_NAME=user
ACCOUNT_PASSWORD=user
VM_NAME=quartus

PATH_TO_VNC_PASS="$(realpath ~/.lima)/$VM_NAME/vncpassword"
GREEN_COLOR='\033[0;32m'
YELLOW_COLOR='\033[0;33m'
RED_COLOR='\033[0;31m'
END_COLOR='\033[0m'

VZ="false"
if [ "$1" = "vz" ]; then
    VZ="true"
    echo "VZ mode will be used."
elif [ "$1" = "qemu" ]; then
    VZ="false"
    echo "Qemu mode will be used"
else
    echo "Usage: $0 mode"
    echo "Virtualization modes:"
    echo "vz - faster solution with Apple Virtualization Framework."
    echo "qemu - slower classical solution. Requires usage of Screen Sharing tool."
    exit 1 
fi

# Check whether VM already exists and exit if so:
if [ -d ~/.lima/$VM_NAME ]; then
    echo -e "${RED_COLOR}$VM_NAME virtual machine is already exist.$END_COLOR"
    echo -e "${RED_COLOR}To run the script delete ${VM_NAME} VM manually:${END_COLOR}"
    echo -e "${YELLOW_COLOR}    limactl delete -f $VM_NAME${END_COLOR}"
    exit 1
fi

# Install lima and create a new VM.
# We can use either vz or qemu for virtualization:
brew install lima wget
mkdir -p ~/.lima/$VM_NAME
if [ "$VZ" = "true" ]; then
    cp lima.yaml.tmpl.vz ~/.lima/$VM_NAME/lima.yaml
else
    cp lima.yaml.tmpl ~/.lima/$VM_NAME/lima.yaml
fi

limactl start $VM_NAME

# Add new user account to VM:
limactl shell $VM_NAME -- sudo adduser --gecos "" --disabled-password "$ACCOUNT_NAME"
limactl shell $VM_NAME -- sudo chpasswd <<<"$ACCOUNT_NAME:$ACCOUNT_PASSWORD"
limactl shell $VM_NAME -- sudo usermod -aG sudo "$ACCOUNT_NAME"

# For aarch64 Ubuntu we need to use qemu-user-static to run the x86_64 Quartus software.
# But due to the bug https://github.com/containers/podman/discussions/22714
# we can't use version from Ubuntu 24.04 repository therefore let's download older version from Ubuntu 23.10:
if [ "$(uname -m)" = "arm64" ]; then
    QEMU_DEB=qemu-user-static_8.0.4+dfsg-1ubuntu3.23.10.5_arm64.deb
    QEMU_DEB_URL=http://launchpadlibrarian.net/721385889/$QEMU_DEB
    for i in {1..5}; do
        wget $QEMU_DEB_URL -O /tmp/lima/$QEMU_DEB
        if [ "$?" -eq 0 ]; then
            break
        fi
        echo -e "${YELLOW_COLOR}Failed to download $QEMU_DEB_URL, retrying...${END_COLOR}"
        sleep 5
    done
    if [ ! -f "/tmp/lima/$QEMU_DEB" ] || [ "$(du -s /tmp/lima/$QEMU_DEB | awk '{print $1}')" -eq 0 ]; then
        echo -e "${RED_COLOR}Failed to download $QEMU_DEB_URL${END_COLOR}"
        echo -e "${RED_COLOR}Please check your internet connection and try again.${END_COLOR}"
        exit 1
    fi
    limactl shell $VM_NAME -- sudo dpkg -i /tmp/lima/$QEMU_DEB
    limactl shell $VM_NAME -- sudo bash -c "echo 'qemu-user-static hold' | sudo dpkg --set-selections"
fi

# apt sources should be patched to support amd64 and i386 binaries:
cp ubuntu.sources /tmp/lima
limactl shell $VM_NAME -- sudo cp /tmp/lima/ubuntu.sources /etc/apt/sources.list.d
limactl shell $VM_NAME -- sudo bash -c "echo 'apt_preserve_sources_list: true' >> /etc/cloud/cloud.cfg"
limactl shell $VM_NAME -- sudo dpkg --add-architecture amd64
limactl shell $VM_NAME -- sudo dpkg --add-architecture i386
limactl shell $VM_NAME -- sudo apt update -y
limactl shell $VM_NAME -- sudo apt upgrade -y

# Install xfce desktop, lightdm, Quartus dependencies and firefox:
limactl shell $VM_NAME -- sudo DEBIAN_FRONTEND=noninteractive apt install -y \
        libxft2:i386 libxext6:i386 libncurses6:i386 \
        bzip2:i386 g++-multilib libglibd-2.0-0:amd64 \
        libfreetype6:amd64 libsm6:amd64 libxrender1:amd64 \
        libfontconfig1:amd64 libxext6:amd64 libcrypt1:amd64
limactl shell $VM_NAME -- sudo DEBIAN_FRONTEND=noninteractive apt install -y \
        xfce4 xfce4-goodies xfce4-session lightdm language-pack-uk
limactl shell $VM_NAME -- sudo apt autoremove -y
limactl shell $VM_NAME -- sudo apt install -y chromium-browser

# Tune configuration to ensure that xfce will be used as a default desktop environment:
limactl shell $VM_NAME -- sudo mkdir -p /var/lib/AccountsService/users/
limactl shell $VM_NAME -- sudo bash -c "echo -e '[org.freedesktop.DisplayManager.AccountsService]\nBackgroundFile='/usr/share/backgrounds/xfce/xfce-shapes.svg'\n\n[User]\nSession=xfce\nXSession=xfce\nIcon=/home/user/.face\nSystemAccount=false' > /var/lib/AccountsService/users/$ACCOUNT_NAME"

# Download quartus installer inside VM and run it:
cp ubuntu_quartus_installer.sh /tmp/lima
limactl shell $VM_NAME -- chmod +x /tmp/lima/ubuntu_quartus_installer.sh
QUARTUS_SUCCESS=true
limactl shell $VM_NAME -- sudo -u $ACCOUNT_NAME /tmp/lima/ubuntu_quartus_installer.sh
if [ $? -ne 0 ]; then
    QUARTUS_SUCCESS=false
    echo -e "${RED_COLOR}Something wrong happened during Quartus installation. Please retry or report the issue.${END_COLOR}"
fi
limactl shell $VM_NAME -- sudo -u $ACCOUNT_NAME ln -s /QuartusVM /home/$ACCOUNT_NAME/QuartusVM

limactl stop $VM_NAME
mkdir -p ~/QuartusVM
sed -i '' 's,#SHARED_FOLDER,  - location\: "~/QuartusVM"\n    mountPoint\: "/QuartusVM"\n    writable: true,g' "$HOME/.lima/$VM_NAME/lima.yaml"
if [ "$VZ" = "true" ]; then
    sed -i '' 's,display: "none",display: "vz",g' "$HOME/.lima/$VM_NAME/lima.yaml"
fi

limactl start $VM_NAME 

if [ "$QUARTUS_SUCCESS" = "false" ]; then
    cp ubuntu_download_and_install_quartus.sh /tmp/lima
    cp InstallQuartus.desktop /tmp/lima
    limactl shell $VM_NAME -- sudo -u $ACCOUNT_NAME cp /tmp/lima/ubuntu_quartus_installer.sh /home/$ACCOUNT_NAME
    limactl shell $VM_NAME -- sudo -u $ACCOUNT_NAME cp /tmp/lima/ubuntu_download_and_install_quartus.sh /home/$ACCOUNT_NAME
    limactl shell $VM_NAME -- sudo chmod +x /home/$ACCOUNT_NAME/ubuntu_download_and_install_quartus.sh
    limactl shell $VM_NAME -- sudo -u $ACCOUNT_NAME cp /tmp/lima/InstallQuartus.desktop /home/$ACCOUNT_NAME/Desktop
fi

if [ "$VZ" = "true" ]; then
    echo -e "\n==========================="
    echo -e "Use the following commands"
    echo -e "${GREEN_COLOR}limactl start ${VM_NAME}${END_COLOR} to start VM"
    echo -e "${GREEN_COLOR}limactl stop ${VM_NAME}${END_COLOR} to stop VM"
    echo -e "===========================\n"
else
    echo -e "\n==========================="
    echo -e "Use ${GREEN_COLOR}Screen Sharing${END_COLOR} tool with parameters:"
    echo -e "   Address: ${GREEN_COLOR}vnc://127.0.0.1:5900${END_COLOR}"
    echo -e "   VNC Password: ${GREEN_COLOR}$(cat ${PATH_TO_VNC_PASS})${END_COLOR}"
    echo -e "   Ubuntu login: ${GREEN_COLOR}$ACCOUNT_NAME${END_COLOR}"
    echo -e "   Ubuntu password: ${GREEN_COLOR}$ACCOUNT_PASSWORD${END_COLOR}"
    echo -e "NOTE: VNC password is stored on your Mac inside ${GREEN_COLOR}${PATH_TO_VNC_PASS}${END_COLOR}"
    echo -e "===========================\n"
fi