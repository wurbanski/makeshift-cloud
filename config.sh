#!/bin/bash

VMFILES=${VMFILES:-~/VMFILES}
mkdir -p $VMFILES/{iso,disk,images,metadata}

declare -A DISTRO_IMAGES
declare -A DISTRO_CHECKSUMS
declare -A DISTRO_OSVARIANT

DISTRO_IMAGES[bionic]=https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
DISTRO_IMAGES[xenial]=https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
DISTRO_IMAGES[centos77]=https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1907.qcow2

DISTRO_CHECKSUMS[bionic]=https://cloud-images.ubuntu.com/bionic/current/SHA256SUMS
DISTRO_CHECKSUMS[xenial]=https://cloud-images.ubuntu.com/xenial/current/SHA256SUMS
DISTRO_CHECKSUMS[centos77]=https://cloud.centos.org/centos/7/images/sha256sum.txt

DISTRO_OSVARIANT[bionic]=ubuntu18.04
DISTRO_OSVARIANT[xenial]=ubuntu16.04
DISTRO_OSVARIANT[centos77]=centos7.0

DISTRO_SELECTOR=$(echo "${!DISTRO_IMAGES[@]}" | awk -v OFS="|" '{$1=$1}1')
