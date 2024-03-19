#!/bin/bash
#function proceed_command () {
#	if ! command -v $1 &> /dev/null; then opkg install --force-overwrite $1; fi
#	
#}
#bash upgrade.sh (online/offline|offline) [needback]

#bg
if ! command -v resize2fs &> /dev/null; then echo -e '\e[91m'$1'cmd_fail! installing pkg\e[0m'
opkg update || true
opkg install fdisk sfdisk losetup resize2fs coreutils-truncate coreutils-dd
if ! command -v resize2fs &> /dev/null; then echo -e '\e[91m'$1'cmd_fail_check your network! \e[0m' && exit 1; fi
fi

function online () {
durl="https://github.com/yoier/r2s-firmware-build/releases/download/"

tagname=`curl -L https://api.github.com/repos/yoier/r2s-firmware-build/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
if [[ $tagname == '' ]]; then echo "check your network" && exit 1; fi

#mount -t tmpfs -o remount,size=850m tmpfs /tmp
rm -rf /tmp/upg && mkdir /tmp/upg && cd /tmp/upg

curl -L -o r2s-ext4-sysupgrade.img.gz ${durl}${tagname}/openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-ext4-sysupgrade.img.gz
sha256numr=`curl -L ${durl}${tagname}/sha256sums | grep "img.gz" | awk '{print $1}'`
}

function offline () {
if [ ! -e /tmp/upload/*.gz ] && [ ! -e /tmp/upload/sha256su* ]; then echo "no update_files in /tmp/upload" && exit 1; fi
#mount -t tmpfs -o remount,size=850m tmpfs /tmp
rm -rf /tmp/upg && mkdir /tmp/upg && cd /tmp/upg
mv /tmp/upload/* /tmp/upg
sha256numr=`cat sha256su* | grep "img.gz" | awk '{print $1}'`
}

function isbackup () {
mkdir -p /mnt/img
mount -t ext4 ${lodev} /mnt/img
echo -e '\e[92mbacking\e[0m'
sleep 10
cd /mnt/img
sysupgrade -b back.tar.gz
tar zxf back.tar.gz --exclude='rc.local'
echo -e '\e[92mbacked,umount\e[0m'
#rm back.tar.gz
cd /tmp/upg
umount /mnt/img
}

if [[ $1 == "online" ]]; then
online
else
offline
fi

if [[ $sha256numr == '' ]]; then echo "sha256=null" && exit 1; fi
sha256numf=$(sha256sum *.gz | awk '{print $1}')
if [[ $sha256numr != $sha256numf ]]; then echo "sha256num ck fail，exit 1" && exit 1; fi
echo "sha256num ck success!"


mv *.gz FriendlyWrt.img.gz
gzip -dv *.gz
block_device='mmcblk0'
bs=`expr $(cat /sys/block/$block_device/size) \* 512`
truncate -s $bs FriendlyWrt.img || ../truncate -s $bs FriendlyWrt.img
echo ", +" | sfdisk -N 2 FriendlyWrt.img
echo -e '\e[92mpackageing...\e[0m'
lodev=$(losetup -f)
losetup -o  100663296 $lodev FriendlyWrt.img
if [[ $2 == needback ]]; then isbackup; fi
sleep 5
if cat /proc/mounts | grep -q ${lodev}; then umount ${lodev}; fi
e2fsck -yf ${lodev} || true
resize2fs ${lodev}
losetup -d $lodev

echo -e '\e[92mwriting...\e[0m'
if [ -f FriendlyWrt.img ]; then
	echo 1 > /proc/sys/kernel/sysrq
	echo u > /proc/sysrq-trigger && umount / || true
	dd if=FriendlyWrt.img of=/dev/$block_device oflag=direct conv=sparse status=progress bs=1M
	echo -e '\e[92mwrited,wait reboot\e[0m'
	echo b > /proc/sysrq-trigger
fi