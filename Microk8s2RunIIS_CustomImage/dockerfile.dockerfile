# escape=`

# =====================================
# Base Image - Official IIS on Windows Server 2022 LTSC
# =====================================
FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022

WORKDIR /inetpub/wwwroot

# =====================================
# Download static content from GitHub
# =====================================
# Download files with curl
RUN powershell -Command "$ErrorActionPreference = 'Stop'; `
    curl.exe -L -o 'Default.htm' 'https://raw.githubusercontent.com/19BlueBomber87/25s-Azure-IaC/main/html/azurehome.html'; `
    New-Item -ItemType Directory -Path 'jpg' -Force; `
    curl.exe -L -o 'jpg/cert.jpg' 'https://raw.githubusercontent.com/19BlueBomber87/25s-Azure-IaC/main/html/cert.jpg'; `
    curl.exe -L -o 'jpg/AquaMoose.jpg' 'https://raw.githubusercontent.com/19BlueBomber87/toDoApp/master/jpg/AquaMoose.jpg'; `
    curl.exe -L -o 'jpg/babymoose2.jpg' 'https://raw.githubusercontent.com/19BlueBomber87/toDoApp/master/jpg/babymoose2.jpg'; `
    curl.exe -L -o 'jpg/bull.jpg' 'https://raw.githubusercontent.com/19BlueBomber87/toDoApp/master/jpg/bull.jpg'; `
    curl.exe -L -o 'jpg/bunny.jpg' 'https://raw.githubusercontent.com/19BlueBomber87/toDoApp/master/jpg/bunny.jpg'; `
    curl.exe -L -o 'jpg/bunny2.jpg' 'https://raw.githubusercontent.com/19BlueBomber87/toDoApp/master/jpg/bunny2.jpg'"

# Copy startup script
COPY startup.ps1 C:\startup.ps1

# Disable auto-start of w3svc
RUN sc config w3svc start= demand

# Exec form ENTRYPOINT: run script → start service → monitor
ENTRYPOINT ["powershell.exe", "-ExecutionPolicy", "Bypass", "-Command", "& C:\\startup.ps1; Start-Service w3svc; C:\\ServiceMonitor.exe w3svc"]


# COPY startup.ps1 C:\startup.ps1
# copies startup.ps1 from the same directory as your Dockerfile (the build context) into the container image at C:\startup.ps1 during the docker build step.
# As long as startup.ps1 is sitting next to your Dockerfile (or in whatever path you specify in the COPY source), Docker will handle copying it into the image automatically. You don't need to manually put anything on C:\ of the host — that's not how Docker builds work.


# FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022
# already contains C:\ServiceMonitor.exe — it's included by Microsoft in the official IIS container images for Windows Server 2022 (and most other recent Windows/IIS images).