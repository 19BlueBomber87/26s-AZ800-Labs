# ===============================================================================
# K8s Lab               Create "k8s Windows Worker Node" Image With a Docker File
#                       Push Docker Image to hub.docker.com
#                       You Can Use Any Windows Server to Create The Docker File, it does not have to be worker node.  
# ===============================================================================
# =============================================================================
#  - Use this image in a Micro k8s cluster to run IIS Pods to serve up a custom website
# =============================================================================
# Author:   Mark Kruse
# Purpose:  Create a Micro k8s cluster to run IIS Pods to serve up a custom website
# Location: Anchorage, Alaska lab environment
# =============================================================================
# =========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/HyperV%20Lab%20Creation%20and%20Disk%20Functions.ps1
# =========================================================================================================================================================
# ===============================================================================
# Step 1 - Build Windows server to create a custome image from Docker file
#          Install Docker
# ===============================================================================
$dockerBuild = "micro-k8s-node-DockerBuild"
New-Lab_VM -VMNames  $dockerBuild -HyperVSwitch Linux-Net -Ram 2GB -GeneralizedImageDE
Stop-VM -VMName $dockerBuild -Force -Verbose *>&1 
Set-VMProcessor -VMName $dockerBuild -ExposeVirtualizationExtensions $true -Verbose *>&1
Start-VM -VMName $dockerBuild -Verbose *>&1
Get-VMProcessor -VMName $dockerBuild | Select-Object VMName, ExposeVirtualizationExtensions
#Rename Worker Node
$WindowsNode = "k8sDockerBuild"
Rename-Computer -NewName $WindowsNode -Verbose *>&1
# Install Required Windows Features
Install-WindowsFeature -Name Containers, Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart


#INSTALL DOCKER
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force -Confirm:$false -Verbose *>&1
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" -OutFile install-docker-ce.ps1
.\install-docker-ce.ps1
docker version
docker info




# ===========================
# Step 2 - Test Dcoker
# ===========================

#Build image from docker file and test pod -> 
#The base image referenced in the DockerFile and website files will take some time to download ->  mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022

# Find Microsoft Images Here -> https://hub.docker.com/u/microsoft
# NOTE: Pull the Base image first for a faster build.  The images are ≈ 4.5GB 
# Overview of Windows Container base images-> https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/container-base-images
# https://hub.docker.com/r/microsoft/windows-servercore-iis


# Docker Run Command Flags - Quick Reference
#  =============================================================================
# Flag                                    | Meaning
# ----------------------------------------|-------------------------------------------------
# --rm                                    | Auto-delete container when it stops/exits
# -d                                      | Run in detached mode (background)
# -it                                     | Interactive + TTY (live output + keyboard input)
# -p 8081:80                              | Map host port 8081 → container port 80
# --name container01-iis01                | Assign a custom name to the container
# custom-iis-site-with-microk8s-ws2025:1.0| The Docker image to run
# =============================================================================
# • Use -it when testing or want to see output directly
# • Use -d for background running
# • --rm keeps your system clean (container is deleted when it stops)
# =============================================================================


# Test 1 Nano Server
# Pull explicitly first (recommended):https://hub.docker.com/_/hello-world/

docker images
docker pull hello-world:nanoserver
docker images


# Random Container Name
docker run -it hello-world:nanoserver cmd

# Set Contianer Name
docker run -it --name my-nano-container hello-world:nanoserver cmd

# Install PowerShell Version 7
mkdir C:\Temp
# Link as of 5-27-2026 
curl -L -o C:\Temp\pwsh.zip https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.6.2-win-x64.zip
tar -xf C:\Temp\pwsh.zip -C C:\Temp
C:\Temp\pwsh.exe
$PSVersionTable
Get-Service;Get-Process;
$ENV:USERNAME

# run as "ContainerAdministrator"
docker run -it --user ContainerAdministrator --name yahoo0100 hello-world:nanoserver cmd
# Install PowerShell Version 7
mkdir C:\Temp
# Link as of 5-27-2026 
curl -L -o C:\Temp\pwsh.zip https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.6.2-win-x64.zip
tar -xf C:\Temp\pwsh.zip -C C:\Temp
C:\Temp\pwsh.exe
$PSVersionTable
Get-Service;Get-Process;
$ENV:USERNAME

# Remove all Containers
docker rm -f $(docker ps -aq)

docker ps -a

# Test 2 Create Hyper-V Isolated Container
docker run -it --isolation=process --user ContainerAdministrator --name yahoo01 hello-world:nanoserver cmd
docker run -it --isolation=hyperv --user ContainerAdministrator --name yahoo02 hello-world:nanoserver cmd

docker pull mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2025
# Takes longer to download
docker pull mcr.microsoft.com/windows/servercore:ltsc2025

docker images
docker run -it --isolation=hyperv hello-world:nanoserver cmd

docker run -it --isolation=hyperv --user ContainerAdministrator --name BEAT-DC01 mcr.microsoft.com/windows/servercore:ltsc2025 powershell
$ENV:USERNAME
Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1

docker run --name BEAT-Web01 -it --isolation=hyperv --user ContainerAdministrator mcr.microsoft.com/windows/nanoserver:ltsc2025
$ENV:USERNAME

# detached mode
docker run -d --name container01-iis01-full mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2025
docker exec -it container01-iis01-full powershell

#check installed roles on container
Get-WindowsFeature  Web-Server, Hyper-V, Containers
exit
# Remove all Containers
docker rm -f $(docker ps -aq)

# ===========================
# Step 3 - Build Image from Docker File
# ===========================

#BUILD IMAGE
mkdir c:\docker-build
notepad c:\docker-build\dockerfile.dockerfile
# Paste this into docker file -> [LINK]

# startup.ps1 is used to present container\hardware information on the home page.
# We bake this into the image.  Its used to get the computer information after the container is created.  
notepad c:\docker-build\startup.ps1
# Paste this into startup.ps1 file -> [LINK]
# Build Image from Docker File
cd C:\docker-build # Change to Directory!!
docker build -f dockerfile.dockerfile -t custom-iis-site-with-microk8s-ws2025:1.0 ./

#remove the container if needed
# docker rmi custom-iis-site-with-microk8s:2.0 --force
# docker rmi mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022

#Check for the custom-iis-azure-demo:2.0 image
docker images

# =============================================================================
# Step 4 - Create a container from the Image that was built from the Docker file
# =============================================================================

# Test -> Quickly Creates and Destorys Containter - 
docker run --rm -d -p 8081:80 --name yahoo-iis01 custom-iis-site-with-microk8s-ws2025:1.0

# Keep container running with -d detached mode
docker run -d -p 8082:80 --name container-iis01 custom-iis-site-with-microk8s-ws2025:1.0 
docker exec container-iis01 powershell -Command "ipconfig"
docker exec -it container-iis01 powershell 

docker exec -it container-iis01 powershell
Get-WindowsFeature  Web-Server, Hyper-V, Containers
Stop-Computer
exit
# Remove Test Container
#get container name
docker ps -a
#remove 
# 2. Same thing but more explicit
docker rm -f container-iis01


# =============================================================================
# Step 4 -Push Image that was built from the Docker file, to hub.docker.com
# =============================================================================
#Push Image to hub.docker.com - We will use a .ymal file to pull the image later
# you need an account at hub.docker.com.  
# Use your the user name of your hub.docker.com account -> https://hub.docker.com/r/mooselover
docker login -u username01
# Tag image
docker image ls
# Image IDs will Match
docker tag custom-iis-site-with-microk8s-ws2025:1.0 mooselover/custom-iis-site-with-microk8s-ws2025:1.0
docker image ls
# Check Image details like RepoTags
docker image inspect custom-iis-site-with-microk8s-ws2025:1.0 
docker image inspect mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022 
# When you create a new repository on Docker Hub by pushing an image (without explicitly creating it first as private), Docker Hub defaults to public.
# Use Tag when pushing!
# docker push yourdockerhubusername/custom-iis-site-with-microk8s-ws2022
docker push mooselover/custom-iis-site-with-microk8s-ws2025:1.0
docker search mooselover/custom-iis-site-with-microk8s-ws2025:1.0

# Remove all Containers
docker rm -f $(docker ps -aq)
# Remove all Images
docker rmi -f $(docker images -q -a)


docker pull mooselover/custom-iis-site-with-microk8s-ws2025:1.0

# Test new Image
docker run -d -p 8081:80 --name yahoo-iis01 mooselover/custom-iis-site-with-microk8s-ws2025:1.0
docker exec yahoo-iis01 powershell -Command "ipconfig"
docker exec -it container-iis01 powershell 
