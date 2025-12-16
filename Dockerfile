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


# RUN chmod +x scripts/setup.sh

# RUN chmod +x scripts/build.sh


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
    echo '    /build/scripts/setup.sh' >> /root/.bashrc && \
    echo 'fi' >> /root/.bashrc && \
    echo 'cat /etc/motd' >> /root/.bashrc

# # Set working directory
# WORKDIR /build

# RUN dos2unix scripts/setup.sh /build/setup.sh
# RUN dos2unix scripts/setup.sh /build/build.sh

# RUN /build/setup.sh

# Default command
CMD ["/bin/bash"]
