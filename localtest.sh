#!/bin/sh

# echo "Starting system with combined image"
# qemu-system-arm \
#     -M vexpress-a9 \
#     -kernel ./output/u-boot/u-boot \
#     -drive file=./output/combined.img,if=sd,format=raw -s -S

qemu-system-arm \
    -M vexpress-a9 \
    -kernel output/kernel/zImage \
    -dtb output/kernel/vexpress-v2p-ca9.dtb \
    -initrd output/initramfs.cpio.gz \
    -append "console=ttyAMA0 rdinit=/init" -nographic -s -S