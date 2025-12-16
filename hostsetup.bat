@echo off
setlocal enabledelayedexpansion
mkdir sources
mkdir output


:: Create named volume for workspace if it doesn't exist
docker volume create arm-linux-workspace

docker build -t arm-linux-build .

:: Set your container and image names
set CONTAINER_NAME=linux_lab
set IMAGE_NAME=arm-linux-build

:: Container doesn't exist, create and start it
echo Container %CONTAINER_NAME% does not exist. Creating and starting...
docker run --privileged -it ^
    --name %CONTAINER_NAME% ^
    -v "%cd%\sources":/build/sources ^
    -v "%cd%\scripts":/build/scripts ^
    -v arm-linux-workspace:/build/workspace ^
    %IMAGE_NAME%


endlocal