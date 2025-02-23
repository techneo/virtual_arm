# Use Ubuntu as base image
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-arm-linux-gnueabi \
    binutils-arm-linux-gnueabi \
    qemu-system-arm \
    qemu-user \
    bc \
    bison \
    flex \
    libssl-dev \
    libelf-dev \
    wget \
    cpio \
    unzip \
    python3 \
    git \
    kmod \
    ncurses-dev \
    swig \
    sudo \
    vim \
    dos2unix \
    dosfstools \
    u-boot-tools \
    dosfstools \
    sudo \
    fdisk \
    mtools \
    parted \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Create directory structure
WORKDIR /build
RUN mkdir -p output/kernel output/modules output/initramfs output/u-boot workspace

# Create setup script
RUN echo '#!/bin/bash' > /build/setup.sh && \
    cat >> /build/setup.sh <<'EOF'
# Create directories if they don't exist
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

# Download any missing sources
cd /build/sources

if [ ! -f linux-6.6.tar.xz ]; then
    echo "Downloading Linux kernel..."
    wget --no-check-certificate https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.tar.xz
    cd /build/workspace
    tar xf /build/sources/linux-6.6.tar.xz
fi

if [ ! -f busybox-1.36.1.tar.bz2 ]; then
    echo "Downloading BusyBox..."
    wget --no-check-certificate https://busybox.net/downloads/busybox-1.36.1.tar.bz2
    cd /build/workspace
    tar xf /build/sources/busybox-1.36.1.tar.bz2
fi

if [ ! -f u-boot-2024.01.tar.bz2 ]; then
    echo "Downloading U-Boot..."
    wget --no-check-certificate https://ftp.denx.de/pub/u-boot/u-boot-2024.01.tar.bz2
    cd /build/workspace
    tar xf /build/sources/u-boot-2024.01.tar.bz2
fi

# Create a flag file to indicate workspace is initialized
touch /build/workspace/.initialized
EOF

RUN chmod +x /build/setup.sh

# Create build script
RUN echo '#!/bin/bash' > /build/build.sh && \
    echo 'set -e' >> /build/build.sh && \
    cat >> /build/build.sh <<'EOF'

# Run setup script first
/build/setup.sh

# Function to build kernel
build_kernel() {
    echo "Building Linux kernel..."
    cd /build/workspace/linux-6.6

    if [ ! -f .config ]; then
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- vexpress_defconfig
        # Enable loadable module support
        sed -i 's/# CONFIG_MODULES is not set/CONFIG_MODULES=y/' .config
        sed -i '/CONFIG_MODULES=y/a CONFIG_MODULE_UNLOAD=y' .config
        sed -i 's/CONFIG_DEBUG_INFO is not set/CONFIG_DEBUG_INFO=y' .config
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- olddefconfig
    fi

    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j$(nproc) zImage modules dtbs
    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- modules_install INSTALL_MOD_PATH=/build/output/modules

    cp arch/arm/boot/zImage /build/output/kernel/
    cp arch/arm/boot/dts/arm/vexpress-v2p-ca9.dtb /build/output/kernel/

    echo "Kernel build completed!"
}

# Function to build busybox and create initramfs
build_busybox() {
    echo "Building BusyBox..."
    cd /build/workspace/busybox-1.36.1

    if [ ! -f .config ]; then
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- defconfig
        sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    fi

    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j$(nproc)

    # Create initramfs structure
    rm -rf /build/output/initramfs/*
    cd /build/output/initramfs
    mkdir -p bin dev proc sys etc lib modules

    # Copy busybox
    cp /build/workspace/busybox-1.36.1/busybox bin/busybox

    # Copy kernel modules if they exist
    if [ -d "/build/output/modules/lib/modules" ]; then
        cp -r /build/output/modules/lib/modules/* lib/modules/
    fi

    # Create init script
    cat > init <<'EOL'
#!/bin/busybox sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Load common modules if they exist
if [ -d "/lib/modules" ]; then
    for module in $(find /lib/modules -name '*.ko'); do
        insmod $module
    done
fi

echo "Boot took $(cut -d' ' -f1 /proc/uptime) seconds"
exec /bin/sh
EOL

    chmod +x init
    chmod +x bin/busybox

    # Create busybox links
    cd bin
    for prog in $(./busybox --list); do
        ln -s busybox $prog
    done

    # Create initramfs
    cd /build/output/initramfs
    find . | cpio -H newc -o | gzip > ../initramfs.cpio.gz

    echo "BusyBox and initramfs build completed!"
}

# Function to build U-Boot
build_uboot() {
    echo "Building U-Boot..."
    cd /build/workspace/u-boot-2024.01

    if [ ! -f .config ]; then
    	echo "Patch config file..."
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- vexpress_ca9x4_defconfig
        
        cat >> .config <<'EOL'
CONFIG_CMD_MMC=y
CONFIG_CMD_FAT=y
CONFIG_CMD_FS_GENERIC=y
CONFIG_MMC=y
CONFIG_GENERIC_MMC=y
CONFIG_ARM_PL180_MMCI=y
CONFIG_MMC_PL180=y
CONFIG_SUPPORT_VFAT=y
CONFIG_CMD_BOOTZ=n
CONFIG_OF_LIBFDT=y
#CONFIG_OF_BOARD_SETUP=y
CONFIG_DEFAULT_FDT_FILE="vexpress-v2p-ca9.dtb"
CONFIG_BOOTDELAY=2
CONFIG_USE_BOOTCOMMAND=y
CONFIG_BOOTCOMMAND="mmc rescan; fatload mmc 0:1 0x60000000 boot.scr; source 0x60000000"
EOL
        
        make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- olddefconfig
    fi

    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j$(nproc)
    cp u-boot /build/output/u-boot/

    echo "U-Boot build completed!"
}

# Function to run system
run_system1() {
    if [ "\$1" == "uboot" ]; then
        qemu-system-arm \
            -M vexpress-a9 \
            -kernel /build/output/u-boot/u-boot \
            -nographic
    else
        qemu-system-arm \
            -M vexpress-a9 \
            -kernel /build/output/kernel/zImage \
            -dtb /build/output/kernel/vexpress-v2p-ca9.dtb \
            -initrd /build/output/initramfs.cpio.gz \
            -append "console=ttyAMA0 rdinit=/init" \
            -nographic
    fi
}

run_system() {
    case $1 in
        "uboot")
            echo "Starting u-boot"   
            qemu-system-arm \
                -M vexpress-a9 \
                -kernel /build/output/u-boot/u-boot \
                -nographic
            ;;
        "combined")
            echo "Starting system with combined image"
            qemu-system-arm \
                -M vexpress-a9 \
                -kernel /build/output/u-boot/u-boot \
                -drive file=/build/output/combined.img,if=sd,format=raw \
                -nographic
            ;;
        *)
            echo "Starting kernel directly"
            qemu-system-arm \
                -M vexpress-a9 \
                -kernel /build/output/kernel/zImage \
                -dtb /build/output/kernel/vexpress-v2p-ca9.dtb \
                -initrd /build/output/initramfs.cpio.gz \
                -append "console=ttyAMA0 rdinit=/init" \
                -nographic
            ;;
    esac
}


# Function to clean build
clean_build() {
    echo "Cleaning build directories..."
    rm -rf /build/output/*
    mkdir -p /build/output/{kernel,modules,initramfs,u-boot}
    
    cd /build/workspace/linux-6.6 && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- clean
    cd /build/workspace/busybox-1.36.1 && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- clean
    cd /build/workspace/u-boot-2024.01 && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- clean
    echo "Clean completed!"
}

create_combined_image() {
    echo "Creating combined boot image..."
    
    # Create an empty image file (64MB)
    dd if=/dev/zero of=/build/output/combined.img bs=1M count=64
    
    # Create partition table
    (
        echo "o" # Create new DOS partition table
        echo "n" # New partition
        echo "p" # Primary partition
        echo "1" # Partition number 1
        echo "2048" # First sector (1MB aligned)
        echo ""  # Default last sector
        echo "t" # Change partition type
        echo "c" # Set type to W95 FAT32 (LBA)
        echo "a" # Make partition bootable
        echo "w" # Write changes
    ) | fdisk /build/output/combined.img

    # Create a temporary file for the filesystem
    dd if=/dev/zero of=/build/output/filesystem.img bs=1M count=63
    
    # Format the filesystem image
    mkfs.vfat /build/output/filesystem.img
    
    # Create U-Boot image for initramfs
    mkimage -A arm -O linux -T ramdisk -C none \
        -n "Initial Ramdisk" \
        -d /build/output/initramfs.cpio.gz /build/output/uRamdisk
    
    # Configure mtools
    export MTOOLS_SKIP_CHECK=1
    cat > /tmp/mtools.conf <<EOL
drive m:
    file="/build/output/filesystem.img"
    offset=0
EOL
    export MTOOLSRC=/tmp/mtools.conf
    
    # Copy files using mtools
    mcopy -i m: /build/output/kernel/zImage m:/
    mcopy -i m: /build/output/kernel/vexpress-v2p-ca9.dtb m:/
    mcopy -i m: /build/output/uRamdisk m:/
    
    # Create boot script
    cat > /tmp/boot.scr.txt <<EOL
setenv bootargs 'console=ttyAMA0 rdinit=/init'
mmc rescan
echo "start"
fatload mmc 0:1 0x60000000 zImage
fatload mmc 0:1 0x61000000 vexpress-v2p-ca9.dtb
fatload mmc 0:1 0x62000000 uRamdisk
bootz 0x60000000 0x62000000 0x61000000
EOL

    # Compile boot script
    mkimage -A arm -O linux -T script -C none -n "Boot Script" \
        -d /tmp/boot.scr.txt /tmp/boot.scr
    
    # Copy boot script
    mcopy -i m: /tmp/boot.scr m:/
    
    # Combine partition table with filesystem
    dd if=/build/output/filesystem.img of=/build/output/combined.img bs=1M seek=1 conv=notrunc
    
    # Cleanup
    # rm -f /build/output/filesystem.img /tmp/boot.scr.txt /tmp/boot.scr /tmp/mtools.conf
    
    echo "Combined image created at /build/output/combined.img"
}

# Main menu function
show_menu() {
    echo "=== ARM Linux Build System ==="
    echo "1. Build Linux Kernel"
    echo "2. Build BusyBox and Initramfs"
    echo "3. Build U-Boot"
    echo "4. Build All"
    echo "5. Run System (Linux + Initramfs)"
    echo "6. Run System with U-Boot"
    echo "7. Run System with Combined Image"
    echo "8. Create Combined Image"
    echo "9. Clean Build"
    echo "10. Exit"
    echo "=========================="
}

while true; do
    show_menu
    read -p "Enter your choice (1-10): " choice

    case $choice in
        1)
            build_kernel
            ;;
        2)
            build_busybox
            ;;
        3)
            build_uboot
            ;;
        4)
            build_kernel
            build_busybox
            build_uboot
            ;;
        5)
            run_system
            ;;
        6)
            run_system uboot
            ;;
        7)
            run_system combined
            ;;
        8)
            create_combined_image
            ;;
        9)
            clean_build
            ;;
        10)
            exit 0
            ;;
        *)
            echo "Invalid choice!"
            ;;
    esac

    echo
    read -p "Press Enter to continue..."
    clear
done
EOF

RUN chmod +x /build/build.sh


# Modify the welcome message to include volume information
RUN echo 'Welcome to ARM Linux Build Environment' > /etc/motd && \
    echo '====================================' >> /etc/motd && \
    echo 'This environment provides tools to build:' >> /etc/motd && \
    echo '- Linux Kernel (6.6)' >> /etc/motd && \
    echo '- BusyBox (1.36.1)' >> /etc/motd && \
    echo '- U-Boot (2024.01)' >> /etc/motd && \
    echo '- Minimal initramfs with module support' >> /etc/motd && \
    echo '' >> /etc/motd && \
    echo 'To start building, run: ./build.sh' >> /etc/motd && \
    echo '' >> /etc/motd && \
    echo 'Notes:' >> /etc/motd && \
    echo '- Source files are in /build/sources/ (persisted on host)' >> /etc/motd && \
    echo '- Built artifacts are stored in /build/output/ (persisted on host)' >> /etc/motd && \
    echo '- Build workspace is in /build/workspace/ (persisted in Docker volume)' >> /etc/motd && \
    echo '- Use Ctrl+A, x to exit QEMU' >> /etc/motd

# Add workspace initialization check to .bashrc
RUN echo 'if [ ! -f /build/workspace/.initialized ]; then' >> /root/.bashrc && \
    echo '    echo "Initializing workspace for first use..."' >> /root/.bashrc && \
    echo '    /build/setup.sh' >> /root/.bashrc && \
    echo 'fi' >> /root/.bashrc && \
    echo 'cat /etc/motd' >> /root/.bashrc

# Set working directory
WORKDIR /build

RUN dos2unix /build/setup.sh /build/build.sh

# Default command
CMD ["/bin/bash"]
