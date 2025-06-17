#!/bin/bash
# Create directories if they don't exist


# Download any missing sources
cd /build/sources

if [ ! -f linux-6.6.tar.xz ]; then
    echo "Downloading Linux kernel..."
    wget --no-check-certificate https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.tar.xz
    cd /build/workspace
    tar xf /build/sources/linux-6.6.tar.xz
fi

cd /build/sources

if [ ! -f busybox-1.36.1.tar.bz2 ]; then
    echo "Downloading BusyBox..."
    wget --no-check-certificate https://busybox.net/downloads/busybox-1.36.1.tar.bz2
    cd /build/workspace
    tar xf /build/sources/busybox-1.36.1.tar.bz2
fi

cd /build/sources

if [ ! -f u-boot-2024.01.tar.bz2 ]; then
    echo "Downloading U-Boot..."
    wget --no-check-certificate https://ftp.denx.de/pub/u-boot/u-boot-2024.01.tar.bz2
    cd /build/workspace
    tar xf /build/sources/u-boot-2024.01.tar.bz2
fi

cd /build/workspace

# Extract sources if not already extracted
if [ ! -d linux-6.6 ] && [ -f /build/sources/linux-6.6.tar.xz ]; then
    echo "Extracting Linux kernel..."
    tar xf /build/sources/linux-6.6.tar.xz
fi

if [ ! -d busybox-1.36.1 ] && [ -f /build/sources/busybox-1.36.1.tar.bz2 ]; then
    echo "Extracting BusyBox..."
    tar xf /build/sources/busybox-1.36.1.tar.bz2
fi

if [ ! -d u-boot-2024.01 ] && [ -f /build/sources/u-boot-2024.01.tar.bz2 ]; then
    echo "Extracting U-Boot..."
    tar xf /build/sources/u-boot-2024.01.tar.bz2
fi

# Create a flag file to indicate workspace is initialized
touch /build/workspace/.initialized
