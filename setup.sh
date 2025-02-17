#!/bin/bash

# Create directory structure
mkdir -p sources
mkdir -p output/u-boot
mkdir -p output/kernel
mkdir -p output/initramfs

# Create named volume for workspace if it doesn't exist
docker volume create arm-linux-workspace

# Build Docker image
docker build -t arm-linux-build .

# Run Docker container
docker run --privileged -it \
    -v "$(pwd)/sources:/build/sources" \
    -v "$(pwd)/output:/build/output" \
    -v arm-linux-workspace:/build/workspace \
    arm-linux-build
