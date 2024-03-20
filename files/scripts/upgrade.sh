#!/bin/bash
#bash upgrade.sh (online/offline|must) (needback/noback|must)
#R2S upgrade scr
#20 5 * * 1 /scripts/upgrade.sh online needback
LOG_FILE="/tmp/update_scr.log"

function loge () {
#red 1;blue 2;green 3
	case $2 in
		red)
			color='\e[91m'
			;;
		blue)
			color='\e[94m'
			;;
		*)
			color='\e[92m'
			;;
	esac
	echo -e ${color}"$1\e[0m"
	echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

function wait_seds() {
	local seconds="$1"
	for ((i = seconds; i >= 1; i--)); do
		echo -ne "\e[92m\rWait $i s...\e[0m"
		sleep 1
	done
		echo "\rOver" green
}

function checkver () {
	#thisver.sha
	thisver=$(cat /thisver.sha)
	if [[ $thisver == $sha256numr ]]; then loge "No update package" blue && exit 0; fi
}

function online () {
	durl="https://github.com/yoier/r2s-firmware-build/releases/download/"
	tagname=`curl -L https://api.github.com/repos/yoier/r2s-firmware-build/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
	if [[ $tagname == '' ]]; then loge "Check your network" red && exit 1; fi
	#mount -t tmpfs -o remount,size=850m tmpfs /tmp
	rm -rf /tmp/upg && mkdir /tmp/upg && cd /tmp/upg
	sha256numr=`curl -L ${durl}${tagname}/sha256sums | grep "img.gz" | awk '{print $1}'`
	if [[ $sha256numr == '' ]]; then loge "SHA256=null" red && exit 1; fi
	checkver
	curl -L -o r2s-ext4-sysupgrade.img.gz ${durl}${tagname}/openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-ext4-sysupgrade.img.gz
}

function offline () {
	if [ ! -e /tmp/upload/*.gz ] && [ ! -e /tmp/upload/sha256su* ]; then loge "No update_files in /tmp/upload/(*.gz,sha256sums)" red && exit 1; fi
	#mount -t tmpfs -o remount,size=850m tmpfs /tmp
	rm -rf /tmp/upg && mkdir /tmp/upg && cd /tmp/upg
	mv /tmp/upload/* /tmp/upg
	sha256numr=`cat sha256su* | grep "img.gz" | awk '{print $1}'`
	if [[ $sha256numr == '' ]]; then loge "sha256=null" red && exit 1; fi
	checkver
}

function isbackup () {
	mkdir -p /mnt/img
	mount -t ext4 ${lodev} /mnt/img
	loge "Backing up" blue
	wait_seds 10
	cd /mnt/img
	sysupgrade -b back.tar.gz
	tar -zxf back.tar.gz --exclude='rc.local'
	echo $sha256numr > thisver.sha
	loge "Restoring backup completed,umount" green
	#rm back.tar.gz
	cd /tmp/upg
	umount /mnt/img
}

#main
case "$1" in
	online|offline)
		loge "Update mode: $1" blue
		;;
	*)
		loge "Unknown parameters: $1,exit 1..."
		exit 1
		;;
esac
case "$2" in
	needback|noback)
		loge "Backup options: $2" blue
		;;
	*)
		loge "Unknown parameters: $2,exit 1..."
		exit 1
		;;
esac
loge "Wait 10 seconds before continuing" red
wait_seds 10

#bg
if ! command -v resize2fs &> /dev/null; then loge "CMD_not_found! installing pkg" red
	opkg update || true
	opkg install fdisk sfdisk losetup resize2fs coreutils-truncate coreutils-dd tar
	if ! command -v resize2fs &> /dev/null; then loge "Installation failed,please check your network!" red && exit 1; else loge "Successful installation" green; fi
fi

if [[ $1 == "online" ]]; then online; else offline; fi

sha256numf=$(sha256sum *.gz | awk '{print $1}')
if [[ $sha256numr != $sha256numf ]]; then loge "SHA256 verification failed!" red && exit 1; fi
loge "sha256 verification successful" green

mv *.gz FriendlyWrt.img.gz
gzip -dv *.gz
block_device='mmcblk0'
bs=`expr $(cat /sys/block/$block_device/size) \* 512`
truncate -s $bs FriendlyWrt.img || ../truncate -s $bs FriendlyWrt.img
echo ", +" | sfdisk -N 2 FriendlyWrt.img
loge "Packing" blue
lodev=$(losetup -f)
losetup -o 100663296 $lodev FriendlyWrt.img
if [[ $2 == "needback" ]]; then isbackup; fi
wait_seds 5
if cat /proc/mounts | grep -q ${lodev}; then umount ${lodev}; fi
e2fsck -yf ${lodev} || true
resize2fs ${lodev}
losetup -d $lodev

loge "writing..." blue
if [ -f FriendlyWrt.img ]; then
	echo 1 > /proc/sys/kernel/sysrq
	echo u > /proc/sysrq-trigger && umount / || true
	dd if=FriendlyWrt.img of=/dev/$block_device oflag=direct conv=sparse status=progress bs=1M
	echo -e '\e[92mwrited,wait reboot\e[0m'
	echo b > /proc/sysrq-trigger
fi
