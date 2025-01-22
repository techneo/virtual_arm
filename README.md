# virtual_arm (Work in progress)

A Docker container to build and run a minimal ARM linux with Busybox

This projects aims at creating a Lab like environment to learn and experiment with Embedded Linux
The activities include

1. Working with the u-boot
2. Building a mainline kernel for Virtual Express Cortex A9
3. Building a minimal initramfs root file system based on busybox
4. Running u-boot on qemu
5. Running kernel on qemu
6. Running a complete embedded setup when u-boot loads the kernel and mounts a rootfs
7. Exposing to u-boot command line environment
8. Exosing to busybox commands
9. Changin kernel config using menu config and rebuilding

# Components ( Downloaded when creating container) 
1. U-boot 2024.1
2. Kernel 6.6
3. Busybox 1.36

# Pre Requesites

Docker (WSL2) on  Windows 
5 GB Hard Disk spave

# Installation

clone the repo and run start.bat from the terminal.

![image](https://github.com/user-attachments/assets/990902d4-c313-4378-bcd4-563722fed678)

After installing all the prerequistes as per the Dockerfile , the container shell would be shown. 

# Execution

From the container shell invoke  build.sh

![image](https://github.com/user-attachments/assets/5deddece-a9ea-4c81-8d88-3bf597c97a17)


## Building

Options 1 2 3 and 4 enable building the individual elements. 

## Executing the Firmware

Options 5 6 7 runs the built firmware on qemu  ( dependency : 1 2 3 8)

# Creating Combined SDCARD image

Option 8 combines all the generated artefacts into a vfat image that can be executed using option 7



