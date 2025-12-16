#!/bin/bash

# Script to add a file to a QEMU disk image at a specific path using loop devices
# Usage: ./add_to_image.sh <disk_image> <file_to_add> <target_path>

set -e  # Exit on any error

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <disk_image> <file_to_add> <target_path>"
    echo "Example: $0 combined.img myfile.txt /usr/local/bin/"
    exit 1
fi

DISK_IMAGE="$1"
FILE_TO_ADD="$2"
TARGET_PATH="$3"
MOUNT_POINT="/tmp/qemu_mount_$$"  # Using $$ to make mount point unique

# Remove trailing slash from target path if present
TARGET_PATH="${TARGET_PATH%/}"

# Check if files exist
if [ ! -f "$DISK_IMAGE" ]; then
    echo "Error: Disk image $DISK_IMAGE not found"
    exit 1
fi

if [ ! -f "$FILE_TO_ADD" ]; then
    echo "Error: File $FILE_TO_ADD not found"
    exit 1
fi

# Create mount point
mkdir -p "$MOUNT_POINT"

cleanup() {
    echo "Cleaning up..."
    if mountpoint -q "$MOUNT_POINT"; then
        umount "$MOUNT_POINT"
    fi
    if [ -n "$LOOP_DEVICE" ]; then
        losetup -d "$LOOP_DEVICE" 2>/dev/null || true
    fi
    rmdir "$MOUNT_POINT" 2>/dev/null || true
}

# Set trap for cleanup on script exit
trap cleanup EXIT

echo "Setting up loop device..."
# Find the first available loop device
LOOP_DEVICE=$(losetup -f)
losetup "$LOOP_DEVICE" "$DISK_IMAGE"

# Find partitions on the loop device
partprobe "$LOOP_DEVICE"
sleep 2

# Determine the partition device
if [ -e "${LOOP_DEVICE}p1" ]; then
    # Some systems use p1, p2, etc. suffix
    PART_DEVICE="${LOOP_DEVICE}p1"
elif [ -e "${LOOP_DEVICE}1" ]; then
    # Some systems use 1, 2, etc. suffix
    PART_DEVICE="${LOOP_DEVICE}1"
else
    # Try to mount the loop device directly if no partitions are found
    PART_DEVICE="$LOOP_DEVICE"
fi

echo "Using partition device: $PART_DEVICE"

echo "Mounting image..."
mount "$PART_DEVICE" "$MOUNT_POINT"

# Create full target path in the mounted image
FULL_TARGET_PATH="${MOUNT_POINT}${TARGET_PATH}"
echo "Creating directory structure: $TARGET_PATH"
mkdir -p "$FULL_TARGET_PATH"

# Get the filename from the source file
FILENAME=$(basename "$FILE_TO_ADD")

echo "Copying file to $TARGET_PATH/$FILENAME"
cp "$FILE_TO_ADD" "$FULL_TARGET_PATH/$FILENAME"

# Set appropriate permissions (modify as needed)
chmod 755 "$FULL_TARGET_PATH/$FILENAME"

echo "Syncing..."
sync

echo "File successfully added to image at $TARGET_PATH/$FILENAME"

# Cleanup is handled by the trap