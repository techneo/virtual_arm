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

#!/bin/bash

CONTAINER_NAME="linux_lab"

# Check if container exists and is running
if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Container ${CONTAINER_NAME} is running. Attaching..."
    docker attach ${CONTAINER_NAME}
elif [ "$(docker ps -aq -f status=exited -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Container ${CONTAINER_NAME} exists but is not running. Starting..."
    docker start -i ${CONTAINER_NAME}
else
    echo "Container ${CONTAINER_NAME} does not exist. Creating and starting..."
    # Run Docker container
    docker run --privileged -it \
        --name=${CONTAINER_NAME} \
        -v "$(pwd)/sources:/build/sources" \
        -v "$(pwd)/output:/build/output" \
        -v arm-linux-workspace:/build/workspace \
        arm-linux-build
fi



