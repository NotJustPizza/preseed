#!/bin/bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "You must provide base image name!"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "Base image doesn't exist!"
  exit 2
fi

_work_dir=$(pwd)
_work_user=$(whoami)
_base_image=$1
_new_image="btrfs-$1"

echo "Adjusting image $_base_image by user $_work_user"

rm -f $_new_image

sudo mkdir /mnt/orginal-iso
sudo mount -o loop $_base_image /mnt/orginal-iso
sudo cp -rT /mnt/orginal-iso /mnt/new-iso

sudo chmod +w -R /mnt/new-iso/install.amd
sudo gunzip /mnt/new-iso/install.amd/initrd.gz
echo preseed.cfg | sudo cpio -H newc -o -A -F /mnt/new-iso/install.amd/initrd
sudo gzip /mnt/new-iso/install.amd/initrd
sudo chmod -w -R /mnt/new-iso/install.amd

cd /mnt/new-iso
sudo md5sum `find -follow -type f` | sudo tee -a md5sum.txt > /dev/null
cd $_work_dir

sudo genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $_new_image /mnt/new-iso &> /dev/null
sudo chown $_work_user:$_work_user $_new_image

sudo umount /mnt/orginal-iso
sudo rmdir /mnt/orginal-iso
sudo rm -r /mnt/new-iso

echo "Image $_new_image has been created"
