#!/bin/bash
set -ue

VMFILES=~/VMFILES
mkdir -p $VMFILES/{iso,disk,images,metadata}

SERVERNAME=$1
DISTRIBUTION=$2

function select_image() {
  case ${DISTRIBUTION} in
    "bionic") echo "bionic-server-cloudimg-amd64.img" ;;
    *) return 1 ;;
  esac
}

function clone_image() {
  qemu-img convert -O qcow2 ${VMFILES}/images/${BASE_IMAGE} ${VMFILES}/disk/${SERVERNAME}.img
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
  virt-install --import --name ${SERVERNAME} \
    --vcpus 2 \
    --memory 8192 \
    --disk ${VMFILES}/disk/${SERVERNAME}.img,device=disk,bus=virtio \
    --disk ${VMFILES}/iso/${SERVERNAME}.iso,device=cdrom \
    --os-type linux --os-variant ubuntu18.04 \
    --virt-type kvm \
    --graphics none \
    --network network=default,model=virtio \
    --noautoconsole
}

BASE_IMAGE=$(select_image)

clone_image

generate_iso

install_vm
