@echo off
setlocal enabledelayedexpansion
mkdir sources
mkdir output
mkdir output\u-boot
mkdir output\kernel
mkdir output\initramfs


:: Create named volume for workspace if it doesn't exist
docker volume create arm-linux-workspace

docker build -t arm-linux-build .

@REM docker run --privileged -it ^
@REM     --name=linux_lab ^
@REM     -v "%cd%\sources":/build/sources ^
@REM     -v "%cd%\output":/build/output ^
@REM     -v arm-linux-workspace:/build/workspace ^
@REM     arm-linux-build


:: Set your container and image names
set CONTAINER_NAME=linux_lab
set IMAGE_NAME=arm-linux-build

:: Check if container exists but is stopped
docker ps -aq -f status=exited -f name=^/%CONTAINER_NAME%$ > nul
if !ERRORLEVEL! EQU 0 (
    echo Container %CONTAINER_NAME% exists but is not running. Starting...
    docker start -i %CONTAINER_NAME%
    goto :eof
)


:: Check if container is running
docker ps -q -f name=^/%CONTAINER_NAME%$ > nul
if !ERRORLEVEL! EQU 0 (
    echo Container %CONTAINER_NAME% is running. Attaching...
    docker attach %CONTAINER_NAME%
    goto :eof
)



:: Container doesn't exist, create and start it
echo Container %CONTAINER_NAME% does not exist. Creating and starting...
docker run --privileged -it ^
    --name %CONTAINER_NAME% ^
    -v "%cd%\sources":/build/sources ^
    -v "%cd%\output":/build/output ^
    -v arm-linux-workspace:/build/workspace ^
    %IMAGE_NAME%