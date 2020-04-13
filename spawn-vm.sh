#!/bin/bash
set -ue

cd "$(dirname $(readlink -f "${BASH_SOURCE}"))"
source config.sh

function print_help() {
  echo -e "Required parameters:"
  echo -e "\t-n\t<server name>"
  echo -e "\t-d\t<linux distro>"
  echo -e "\nOptional parameters"
  echo -e "-s\t<main disk size, for example: '-s 10G' >"
  echo -e "-c\t<virsh connection string>"
  echo -e "-i\t<network name to use with main network interface>\n"
}

function select_image() {
  if [ ${DISTRO_IMAGES[${DISTRIBUTION}]+_} ]; then
		export OSVARIANT=${DISTRO_OSVARIANT[$DISTRIBUTION]}
		export BASE_IMAGE=$(basename ${DISTRO_IMAGES[$DISTRIBUTION]})
  else
		return 1;
	fi
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
  echo "local-hostname: ${SERVERNAME}" > ${server_metadata}/meta-data

  
  cat <<EOF >${server_metadata}/user-data
#cloud-config
growpart: { mode: auto }
hostname: ${SERVERNAME}
local_hostname: ${SERVERNAME}
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

if (( $# == 0 )); then
	print_help; exit 1
fi

while getopts "n:d:s:c:h" opt;
do
  case $opt in
    n) SERVERNAME=${OPTARG} ;;
    d) DISTRIBUTION=${OPTARG} ;;
    s) DISKSIZE=${OPTARG} ;;
    c) VIRSHCONNECTPARAM="--connect ${OPTARG}" ;;
    i) NETWORK=${OPTARG} ;;
    h|*) print_help; exit 1;;
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
