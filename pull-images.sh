#!/bin/bash
set -e
set -x

source config.sh

function fetch_checksum() {
	local DISTR=$1
	local URL=$2
	local FILENAME=$3

	wget -q $URL -O ${DISTR}.tmp.sha256
	echo $(grep $FILENAME\$ ${DISTR}.tmp.sha256 | awk '{ print $1}') ${DISTR}.tmp > ${DISTR}.sha256
	echo $(grep $FILENAME\$ ${DISTR}.tmp.sha256 | awk '{ print $1}') $FILENAME >> ${DISTR}.sha256
}

cd $VMFILES/images
for distr in "${!DISTRO_IMAGES[@]}"; do
	echo Downloading \"${distr}\" checksums...
	filename=$(basename ${DISTRO_IMAGES[$distr]})

	fetch_checksum ${distr} ${DISTRO_CHECKSUMS[$distr]} $filename

	if ! sha256sum --ignore-missing -c ${distr}.sha256; then
		echo "File changed, downloading..."
		wget --show-progress -q ${DISTRO_IMAGES[$distr]} -O ${distr}.tmp

		if sha256sum --ignore-missing -c ${distr}.sha256; then
			echo Download complete!
			mv ${distr}.tmp $filename
			rm ${distr}.tmp.sha256 ${distr}.sha256
		else
			echo Checksums don\'t match...
			rm ${distr}.tmp ${distr}.tmp.sha256 ${distr}.sha256 
		fi
	else
		echo "Image not changed, skipping."
    rm ${distr}.tmp.sha256 ${distr}.sha256
	fi
done

