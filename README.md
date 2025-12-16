# ARM 32bit Lab Environment

This project is a simple lab environment for ARM 32bit Processor .  

## Pipeline 

Windows/Linux -> Docker -> Qemu -> Linux for ARM

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

## Introduction

The scripts are designed to download the source code for the linux kernel , u-boot and busybox.
List:
     [Busybox 1.36.1](sources/busybox-1.36.1.tar.bz2)
     [Kernel 6.6](sources/linux-6.6.tar.xz)
     [u-boot 2024.01](sources/u-boot-2024.01.tar.bz2)

The docker file spins a Ubuntu 22.04 image and sets it up with tools and packages needed to build and run the linux distro.

Packages:
    build-essential,
    gcc-arm-linux-gnueabi,
    binutils-arm-linux-gnueabi,
    qemu-system-arm,
    qemu-user,
    bc,
    bison,
    flex,
    libssl-dev,
    libelf-dev,
    wget,
    cpio,
    unzip,
    python3,
    git,
    kmod,
    ncurses-dev,
    swig,
    sudo,
    vim,
    dos2unix,
    dosfstools,
    u-boot-tools,
    dosfstools,
    sudo,
    fdisk,
    mtools,
    parted,
    nano

## Usage

Based on the OS , lauch the setup.bat or setup.sh from the terminal

For the first run , the script builds the Ubuntu system , downloads the source and sets up the needed directories.

Features:

1. Build and run u-boot
2. Build and run the Kernel
3. Build a combined image using the uboot , kernel and busybox to get a simple initramfs
4. Develop simple kernel modules ( hello provided for reference)

[More details here](Usage.md)

## Future

1. Debug kernel support
2. Debug u-boot 
3. Add a fullfledged rootfs
