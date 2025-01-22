@echo off
mkdir sources 2>nul
mkdir output 2>nul
mkdir output/u-boot 2>nul
mkdir output/kernel 2>nul
mkdir output/initramfs 2>nul

:: Create named volume for workspace if it doesn't exist
docker volume create arm-linux-workspace

docker build -t arm-linux-build .

docker run --privileged -it ^
    -v "%cd%\sources":/build/sources ^
    -v "%cd%\output":/build/output ^
    -v arm-linux-workspace:/build/workspace ^
    arm-linux-build