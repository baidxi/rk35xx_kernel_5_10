#!/bin/bash
rm -rf ${1}.dtb
dtc -I dts -O dtb ${1}.dts -o ${1}.dtb
${PWR_ROOT} cp -rf  ${1}.dtb  	${RK3188_IMAGE}/dtb/rk3188.dtb