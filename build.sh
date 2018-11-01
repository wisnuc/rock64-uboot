#!/bin/bash

set -e

# clean
make distclean

# set config file
make CROSS_COMPILE=aarch64-linux-gnu- rock64-rk3328_defconfig
# cp configs/rock64-rk3328_defconfig .config

# generate spl
make CROSS_COMPILE=aarch64-linux-gnu- BL31=rkbin/rk3328_bl31_v1.39.bin -j 8

# generate u-boot.itb
make DEBUG=1 CROSS_COMPILE=aarch64-linux-gnu- BL31=rkbin/rk3328_bl31_v1.39.bin -j 8 u-boot.itb

# generate image with ddr initializer
tools/mkimage -n rk3328 -T rksd -d rkbin/rk3328_ddr_786MHz_v1.13.bin idbloader.img

# append spl
cat spl/u-boot-spl.bin >> idbloader.img

# insert uboot
dd if=u-boot.itb of=idbloader.img seek=$((0x200-64)) conv=notrunc

# dup
cp idbloader.img rksd_loader.img



