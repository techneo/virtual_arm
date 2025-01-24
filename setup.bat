@echo off
mkdir sources
mkdir output
mkdir output\u-boot
mkdir output\kernel
mkdir output\initramfs


:: Create named volume for workspace if it doesn't exist
docker volume create arm-linux-workspace

docker build -t arm-linux-build .

docker run --privileged -it ^
    -v "%cd%\sources":/build/sources ^
    -v "%cd%\output":/build/output ^
    -v arm-linux-workspace:/build/workspace ^
    arm-linux-build