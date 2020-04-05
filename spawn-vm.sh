#!/bin/bash
set -ue

VMFILES=${VMFILES:-~/VMFILES}
mkdir -p $VMFILES/{iso,disk,images,metadata}

function print_help() {
  echo -e "Required parameters:"
  echo -e "\t-n\t<server name>"
  echo -e "\t-d\t<linux distro>"
  echo -e "\nOptional parameters"
  echo -e "-s\t<main disk size, for example: '-s 10G' >"
  echo -e "-c\t<virsh connection string>"
  echo -e "-i\t<network name to use with main network interface>\n"
  exit 1
}

function select_image() {
  case ${DISTRIBUTION} in
    "bionic") 
       export BASE_IMAGE="bionic-server-cloudimg-amd64.img"
       export OSVARIANT="ubuntu18.04"
       ;;
    "xenial") 
       export BASE_IMAGE="xenial-server-cloudimg-amd64-disk1.img"
       export OSVARIANT="ubuntu16.04"
       ;;
    *) return 1 ;;
  esac
}

function clone_image() {
  qemu-img convert -p -O qcow2 ${VMFILES}/images/${BASE_IMAGE} ${VMFILES}/disk/${SERVERNAME}.img
}

function resize_image() {
  qemu-img resize ${VMFILES}/disk/${SERVERNAME}.img $DISKSIZE
}

function generate_iso () {
  local server_metadata=${VMFILES}/metadata/${SERVERNAME}
  mkdir -p ${server_metadata}
  echo "instance-id: $(uuidgen)" > ${server_metadata}/meta-data
  
  cat <<EOF >${server_metadata}/user-data
#cloud-config
growpart: { mode: auto }
hostname: ${SERVERNAME}
power_state: { mode: reboot }
ssh_authorized_keys:
  - $(cat ~/.ssh/id_rsa.pub || echo "")
EOF

  cloud-localds ${VMFILES}/iso/${SERVERNAME}.iso ${server_metadata}/{user,meta}-data
}

function install_vm() {
  virt-install ${VIRSHCONNECTPARAM} --import --name ${SERVERNAME} \
    --vcpus 2 \
    --memory 8192 \
    --disk ${VMFILES}/disk/${SERVERNAME}.img,device=disk,bus=virtio \
    --disk ${VMFILES}/iso/${SERVERNAME}.iso,device=cdrom \
    --os-type linux --os-variant ${OSVARIANT} \
    --virt-type kvm \
    --graphics none \
    --network network=${NETWORK},model=virtio \
    --noautoconsole
}

while getopts "n:d:s:c:" arg;
do
  case $arg in
    n) SERVERNAME=${OPTARG} ;;
    d) DISTRIBUTION=${OPTARG} ;;
    s) DISKSIZE=${OPTARG} ;;
    c) VIRSHCONNECTPARAM="--connect ${OPTARG}" ;;
    i) NETWORK=${OPTARG} ;;
    *) print_help ;;
  esac
done

DISKSIZE=${DISKSIZE:-DONT_RESIZE}
VIRSHCONNECTPARAM=${VIRSHCONNECTPARAM:-""}
NETWORK=${NETWORK:-default}

select_image

clone_image

if [ "$DISKSIZE" != "DONT_RESIZE" ]
then
  resize_image
fi

generate_iso

install_vm
