#!/bin/bash
set -o errexit

clear
printf "\n*** This script will download a cloud image and create a Proxmox VM template from it. ***\n\n"

### From: https://bbs.xmbillion.com/thread-77.htm
### HOW TO USE
### Pre-req:
### - run on a Proxmox 6 server
### - a dhcp server should be active on vmbr1
###
### - fork the gist and adapt the defaults (especially SSHKEY) as needed
### - download latest version of the script:
###   curl wget https://gist.githubusercontent.com/chriswayg/43fbea910e024cbe608d7dcb12cb8466/raw/create-cloud-template.sh > /usr/local/bin/create-cloud-template.sh && chmod -v +x /usr/local/bin/create-cloud-template.sh
### - (optionally) prepare a cloudinit user-config.yml in the working directory
###   this could be copied and modified from the cloudinit user dump at the end of this script
### - run the script:
###   $ create-cloud-template.sh
### - clone the finished template from the Proxmox GUI and test
###
### NOTES:
### - links to cloud images:
###   Directory: https://docs.openstack.org/image-guide/obtain-images.html
###   Debian http://cdimage.debian.org/cdimage/openstack/
###   Ubuntu http://cloud-images.ubuntu.com/
###   CentOS: http://cloud.centos.org/centos/7/images/
###   CentOS: https://cloud.centos.org/centos/8/x86_64/images/
###   AlmaLinux: https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/
###   Fedora: https://alt.fedoraproject.org/cloud/
###   SUSE 15 SP1 JeOS: https://download.suse.com/Download?buildid=OE-3enq3uys~
###   CirrOS http://download.cirros-cloud.net/
###   CoreOS (EOL 05.2020): https://stable.release.core-os.net/amd64-usr/current/
###   Flatcar (CoreOS fork): https://stable.release.flatcar-linux.net/amd64-usr/current/
###   Gentoo: http://gentoo.osuosl.org/experimental/amd64/openstack
###   Arch (also Gentoo): https://linuximages.de/openstack/arch/
###   Alpine: https://github.com/chriswayg/packer-qemu-cloud/
###   RancherOS: https://github.com/rancher/os/releases (also includes Proxmox iso version)
###
### - most links will download the latest current (stable) version of the OS
### - older cloud-init versions do not support hashed passwords

## TODO
## - verify authenticity of downloaded images using hash or GPG

printf "* Available templates to generate:\n 2) Debian 9\n 3) Debian 10\n 4) Ubuntu 18.04\n 5) Ubuntu 20.04\n 6) Ubuntu 20.10\n 7) Ubuntu 21.04\n 8) Centos 6.8\n 9) Centos 6.10\n 10) Centos 7.1\n 11) Centos 7.2\n 12) Centos 7.3\n 13) Centos 7.4\n 14) Centos 7.5\n 15) Centos 7.6\n 16) Centos 7.7\n 17) Centos 7.8\n 18) Centos 8.1\n 19) Centos 8.2\n 20) Centos 8.3\n 21) Centos 8.4\n\n"
read -p "* Enter number of distro to use: " OSNR

# defaults which are used for most templates
RESIZE=+30G
MEMORY=2048
BRIDGE=vmbr1
USERCONFIG_DEFAULT=none # cloud-init-config.yml
CITYPE=nocloud
SNIPPETSPATH=/var/lib/vz/snippets
SSHKEY=~/.ssh/2019_id_rsa.pub # ~/.ssh/id_rsa.pub
NOTE=""

case $OSNR in

  2)
    OSNAME=debian9
    VMID_DEFAULT=51100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    VMIMAGE=debian-9-openstack-amd64.qcow2
    NOTE="\n## Default user is 'debian'\n## NOTE: Setting a password via cloud-config does not work.\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cdimage.debian.org/cdimage/openstack/current-9/$VMIMAGE
    ;;

  3)
    OSNAME=debian10
    VMID_DEFAULT=51200
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    VMIMAGE=debian-10-openstack-amd64.qcow2
    NOTE="\n## Default user is 'debian'\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cdimage.debian.org/cdimage/openstack/current-10/$VMIMAGE
    ;;

  4)
    OSNAME=ubuntu1804
    VMID_DEFAULT=52000
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    VMIMAGE=bionic-server-cloudimg-amd64.img
    NOTE="\n## Default user is 'ubuntu'\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cloud-images.ubuntu.com/bionic/current/$VMIMAGE
    ;;

  5)
    OSNAME=ubuntu2004
    VMID_DEFAULT=52004
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    VMIMAGE=focal-server-cloudimg-amd64.img
    NOTE="\n## Default user is 'ubuntu'\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cloud-images.ubuntu.com/focal/current/$VMIMAGE
    ;;

  6)
    OSNAME=ubuntu2010
    VMID_DEFAULT=52010
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    VMIMAGE=groovy-server-cloudimg-amd64.img
    NOTE="\n## Default user is 'ubuntu'\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cloud-images.ubuntu.com/groovy/current/$VMIMAGE
    ;;

   7)
    OSNAME=ubuntu2104
    VMID_DEFAULT=52104
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    VMIMAGE=hirsute-server-cloudimg-amd64.img
    NOTE="\n## Default user is 'ubuntu'\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cloud-images.ubuntu.com/hirsute/current/$VMIMAGE
    ;;

  8)
    OSNAME=centos6.8
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-6-x86_64-GenericCloud-1607.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/6/images/$VMIMAGE
    ;;

  9)
    OSNAME=centos6.10
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-6-x86_64-GenericCloud-1907.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/6/images/$VMIMAGE
    ;;

  10)
    OSNAME=centos7.1
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-7-x86_64-GenericCloud-1503.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/7/images/$VMIMAGE
    ;;

  11)
    OSNAME=centos7.2
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-7-x86_64-GenericCloud-1511.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/7/images/$VMIMAGE
    ;;

  12)
    OSNAME=centos7.3
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-7-x86_64-GenericCloud-1611.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/7/images/$VMIMAGE
    ;;

  13)
    OSNAME=centos7.4
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-7-x86_64-GenericCloud-1708.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/7/images/$VMIMAGE
    ;;

  14)
    OSNAME=centos7.5
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-7-x86_64-GenericCloud-1804_02.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/7/images/$VMIMAGE
    ;;

  15)
    OSNAME=centos7.6
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-7-x86_64-GenericCloud-1811.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/7/images/$VMIMAGE
    ;;

  16)
    OSNAME=centos7.7
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-7-x86_64-GenericCloud-1907.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/7/images/$VMIMAGE
    ;;

  17)
    OSNAME=centos7.8
    VMID_DEFAULT=53100
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-7-x86_64-GenericCloud-2003.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos7-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N http://cloud.centos.org/centos/7/images/$VMIMAGE
    ;;

  18)
    OSNAME=centos8.1
    VMID_DEFAULT=53108
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-8-GenericCloud-8.1.1911-20200113.3.x86_64
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos8-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cloud.centos.org/centos/8/x86_64/images/$VMIMAGE
    ;;

  19)
    OSNAME=centos8.2
    VMID_DEFAULT=53108
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-8-GenericCloud-8.2.2004-20200611.2.x86_64.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos8-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cloud.centos.org/centos/8/x86_64/images/$VMIMAGE
    ;;

  20)
    OSNAME=centos8.3
    VMID_DEFAULT=53108
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-8-GenericCloud-8.3.2011-20201204.2.x86_64.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos8-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cloud.centos.org/centos/8/x86_64/images/$VMIMAGE
    ;;

  21)
    OSNAME=centos8.4
    VMID_DEFAULT=53108
    read -p "Enter a VM ID for $OSNAME [$VMID_DEFAULT]: " VMID
    VMID=${VMID:-$VMID_DEFAULT}
    RESIZE=+24G
    VMIMAGE=CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2
    NOTE="\n## Default user is 'centos'\n## NOTE: CentOS ignores hostname config.\n#  use 'hostnamectl set-hostname centos8-cloud' inside VM\n"
    printf "$NOTE\n"
    wget -P /tmp -N https://cloud.centos.org/centos/8/x86_64/images/$VMIMAGE
    ;;


  *)
    printf "\n** Unknown OS number. Please use one of the above!\n"
    exit 0
    ;;
esac

[[ $VMIMAGE == *".bz2" ]] \
    && printf "\n** Uncompressing image (waiting to complete...)\n" \
    && bzip2 -d --force /tmp/$VMIMAGE \
    && VMIMAGE=$(echo "${VMIMAGE%.*}") # remove .bz2 file extension from file name

# TODO: could prompt for the VM name
printf "\n** Creating a VM with $MEMORY MB using network bridge $BRIDGE\n"
qm create $VMID --name $OSNAME-cloud --memory $MEMORY --net0 virtio,bridge=$BRIDGE

printf "\n** Importing the disk in qcow2 format (as 'Unused Disk 0')\n"
qm importdisk $VMID /tmp/$VMIMAGE local -format qcow2

printf "\n** Attaching the disk to the vm using VirtIO SCSI\n"
qm set $VMID --scsihw virtio-scsi-pci --scsi0 /var/lib/vz/images/$VMID/vm-$VMID-disk-0.qcow2

printf "\n** Setting boot and display settings with serial console\n"
qm set $VMID --boot c --bootdisk scsi0 --serial0 socket --vga serial0

printf "\n** Using a dhcp server on $BRIDGE (or change to static IP)\n"
qm set $VMID --ipconfig0 ip=dhcp
#This would work in a bridged setup, but a routed setup requires a route to be added in the guest
#qm set $VMID --ipconfig0 ip=10.10.10.222/24,gw=10.10.10.1

printf "\n** Creating a cloudinit drive managed by Proxmox\n"
qm set $VMID --ide2 local:cloudinit

printf "\n** Specifying the cloud-init configuration format\n"
qm set $VMID --citype $CITYPE

printf "#** Made with create-cloud-template.sh - by www.xmbillion.com\n" >> /etc/pve/qemu-server/$VMID.conf

## TODO: Also ask for a network configuration. Or create a config with routing for a static IP
printf "\n*** The script can add a cloud-init configuration with users and SSH keys from a file in the current directory.\n"
read -p "Supply the name of the cloud-init-config.yml (this will be skipped, if file not found) [$USERCONFIG_DEFAULT]: " USERCONFIG
USERCONFIG=${USERCONFIG:-$USERCONFIG_DEFAULT}
if [ -f $PWD/$USERCONFIG ]
then
    # The cloud-init user config file overrides the user settings done elsewhere
    printf "\n** Adding user configuration\n"
    cp -v $PWD/$USERCONFIG $SNIPPETSPATH/$VMID-$OSNAME-$USERCONFIG
    qm set $VMID --cicustom "user=local:snippets/$VMID-$OSNAME-$USERCONFIG"
    printf "#* cloud-config: $VMID-$OSNAME-$USERCONFIG\n" >> /etc/pve/qemu-server/$VMID.conf
else
    # The SSH key should be supplied either in the cloud-init config file or here
    printf "\n** Skipping config file, as none was found\n\n** Adding SSH key\n"
    qm set $VMID --sshkey $SSHKEY
    printf "\n"
    read -p "Supply an optional password for the default user (press Enter for none): " PASSWORD
    [ ! -z "$PASSWORD" ] \
        && printf "\n** Adding the password to the config\n" \
        && qm set $VMID --cipassword $PASSWORD \
        && printf "#* a password has been set for the default user\n" >> /etc/pve/qemu-server/$VMID.conf
    printf "#- cloud-config used: via Proxmox\n" >> /etc/pve/qemu-server/$VMID.conf
fi

# The NOTE is added to the Summary section of the VM (TODO there seems to be no 'qm' command for this)
printf "#$NOTE\n" >> /etc/pve/qemu-server/$VMID.conf

printf "\n** Increasing the disk size\n"
qm resize $VMID scsi0 $RESIZE

printf "\n*** The following cloud-init configuration will be used ***\n"
printf "\n-------------  User ------------------\n"
qm cloudinit dump $VMID user
printf "\n-------------  Network ---------------\n"
qm cloudinit dump $VMID network

# convert the vm into a template (TODO make this optional)
qm template $VMID

printf "\n** Removing previously downloaded image file\n\n"
rm -v /tmp/$VMIMAGE

printf "$NOTE\n\n"
