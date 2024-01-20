#!/bin/bash

FAT_IMAGE="./kernel.fat"
KNL_ADDR="0x80000000"
KNL_IMAGE="arch/arm64/boot/Image.gz"
DTB_IMAGE="./arch/arm64/boot/dts/rockchip/rk3568-sunniwell.dtb"

TARGET_IMG="$1"
MODULES_LIB=./modules-lib


function do_make()
{
	if [ "${TARGET_IMG}x" = "x" ] ; then
		echo "make kernel "
		rm -rf ${KNL_IMAGE}
		threads=`sed -n "N;/processor/p" /proc/cpuinfo|wc -l`
		make Image.gz --jobs=$((${threads} - 4))
#mkimage -A arm -O linux -T kernel -C none -a ${KNL_ADDR} -e ${KNL_ADDR} -n "ARM64 Linux-5.10" -d ${KNL_IMAGE} uImage.img
	elif [ "${TARGET_IMG}x" = "modulesx" ] ; then
		make modules
	else
		echo "make dtbs"
		make dtbs
#	make rk3568-sunniwell.img
	fi
}


function rm_modules()
{
	echo "remove all ko modules"

	rm -rf ${MODULES_LIB}/*

	files=$(find ./ -name *.ko)
	for f in $files ; do
		rm -rf $f 
	done
}

function update_modules()
{
	echo "update all ko modules"

	[ ! -e ${MODULES_LIB} ] && mkdir  ${MODULES_LIB}

	files=$(find ./ -name *.ko)
	for f in $files ; do
		fpath=$(dirname $f)
		IFS='/' read -ra parts <<< "$fpath"
		fname=${parts[-1]}
		floader="${MODULES_LIB}/${fname}"
		[ ! -e ${floader} ] && mkdir ${floader}
		cp -rf $f  ${floader}/
	done

	tar -cvf ${MODULES_LIB}.tar ${MODULES_LIB}
}

function update_images()
{
	echo "update kernel.fat uImage.dtb modules.tar uImage.img"
	${PWR_ROOT} cp -rf 	${KNL_IMAGE} 	${RK3568_IMAGE}/uImage.img
	${PWR_ROOT} cp -rf 	${FAT_IMAGE} 	${RK3568_IMAGE}
	${PWR_ROOT} cp -rf  ${DTB_IMAGE}  	${RK3568_IMAGE}/uImage.dtb
	${PWR_ROOT} cp -rf  ${MODULES_LIB}.tar  	${RK3568_IMAGE}/
}

function make_fatfs()
{
	# ls -hl arch/arm/boot/uImage | awk '{print $5}'
	sudo mkdir kernel_tmp
	sudo dd if=/dev/zero of=${FAT_IMAGE} bs=1M count=20
	sudo mkfs.fat ${FAT_IMAGE}
	sudo mount   ${FAT_IMAGE}  ./kernel_tmp
	sudo cp -rf  ${KNL_IMAGE}  ./kernel_tmp/uImage.img
	sudo cp -rf  ${DTB_IMAGE}  ./kernel_tmp/uImage.dtb
	sudo umount ./kernel_tmp
	sudo rm -rf  ./kernel_tmp
}


rm_modules
do_make
make_fatfs
update_modules
update_images

echo "$(date)"
