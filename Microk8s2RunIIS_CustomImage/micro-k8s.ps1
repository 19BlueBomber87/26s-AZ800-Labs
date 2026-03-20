# =============================================================================
# Hyper-V Lab Creation - Micro k8s cluster to run IIS Pods to serve up a custom website
# =============================================================================
# Author:   Mark Kruse
# Purpose:  Create a Micro k8s cluster to run IIS Pods to serve up a custom website
# Location: Anchorage, Alaska lab environment
# =============================================================================
# =========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-QuickCreate-GoldenImages/AZ-800Celebrate-HyperV%20Creation%20and%20Disk%20Functions.ps1
# =========================================================================================================================================================
# ==============================
New-Lab_VM -VMNames micro-k8s -HyperVSwitch Linux-NET -ISOPath C:\ISO\ubuntu-24.04.3-live-server-amd64.iso -RAM_GB 2GB
Stop-VM -VMName micro-k8s -Force -Verbose *>&1
Set-VMFirmware -VMName micro-k8s -EnableSecureBoot off -Verbose *>&1
Start-VM -VMName micro-k8s -Verbose *>&1
# ===============================================================================
# Step 1 -CONTROL PLANE
#         Install Micro K8s and configure server allow for Windows Nodes to join.  
# ===============================================================================

# Install Micro-K8s
# sudo snap install microk8s --classic --channel=1.35/stable
sudo snap install microk8s --classic
sudo microk8s start

# Set Permmission
sudo usermod -a -G microk8s admin01
# Log out and back in (or open new terminal)

#Check Status
sudo microk8s kubectl version
#Wait for Kubernetes to be ready

# Enable useful MicroK8s add-ons
# sudo microk8s enable dns dashboard storage ingress metallb:192.168.88.100-192.168.88.200

# Enable DNS Storage and Dashboard
sudo microk8s enable dns 
sudo microk8s enable hostpath-storage
sudo microk8s enable dashboard

# Check kubectl pods
# WARNING, you need to wait untill all these pods are up
sudo microk8s kubectl get pods -A
#Use kubectl (MicroK8s bundles it)

alias kubectl='microk8s kubectl'
#Alias for convenience (add to ~/.bashrc):
 
# Determine the exact version of Kubernetes running in the cluster, e.g. 1.27.1. You can use the following command:
sudo microk8s kubectl get node -o wide
# containerd://1.7.27

# Determine the exact version of Calico running in the MicroK8s cluster, e.g. 3.25.0. For this, you can inspect the image used by the calico-node containers:
sudo microk8s kubectl get ds/calico-node -n kube-system -o jsonpath='{.spec.template.spec.containers[?(.name=="calico-node")].image}{"\n"}'
#OUTPUT ->  docker.io/calico/node:v3.29.3

# Generate a kubeconfig file for the MicroK8s cluster. You will need this to run calicoctl commands, and later copy it to the Windows node.
mkdir -p ~/.kube
sudo chown -f -R admin01 ~/.kube
sudo microk8s config > ~/.kube/config

# Check Control Plane Node.  It should have a "Ready" Status
sudo microk8s kubectl get nodes



# In order for Windows pods to schedule, strict affinity must be set to true. This is required to prevent Linux nodes from borrowing IP addresses from Windows nodes. 
# This can be set with the calicoctl binary. Install the calicoctl binary your version of Calico.  
CALICO_VERSION="3.29.3"
curl -L https://github.com/projectcalico/calico/releases/download/v$CALICO_VERSION/calicoctl-linux-amd64 -o calicoctl
chmod +x ./calicoctl

# Check calicoctl version and nodes
./calicoctl version
./calicoctl get nodes
# etc.

# (set the environment variable to the appropriate version of Calico for your system)
# Then, set strict affinity to true with the following command:
./calicoctl ipam configure --strictaffinity=true --allow-version-mismatch



# ===============================================================================
# Step 2 -Create Windows-Worker Nodes
#         Enable Nested virtualization
#         Install Required Windows Features
# ===============================================================================
New-Lab_VM -VMNames micro-k8s-node01 -HyperVSwitch Linux-Net -GeneralizedImageCore
# Enable Nested virtualization
Stop-VM -VMName micro-k8s-node01 -Force -Verbose *>&1 
Set-VMProcessor -VMName micro-k8s-node01 -ExposeVirtualizationExtensions $true -Verbose *>&1
Start-VM -VMName micro-k8s-node01 -Verbose *>&1

#Rename Worker Node
Rename-Computer -NewName k8s-node01 -Restart -Verbose *>&1


# Install Required Windows Features
Install-WindowsFeature -Name Containers, Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart

#NOTE: If you Already have image, skip to step 4

# ===============================================================================
# Step 3 -Create k8s Worker Node Docker Image With a Docker File
#         Push Docker Image to hub.docker.com
#         You Can Use Any Windows Server to Create The Docker File, it does not have to be worker node.  
# ===============================================================================

#INSTALL DOCKER
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" -OutFile install-docker-ce.ps1
.\install-docker-ce.ps1
docker version
docker info
docker run hello-world:nanoserver   # Or mcr.microsoft.com/windows/nanoserver:ltsc2022 for a Windows test


#BUILD IMAGE
mkdir c:\docker-build
notepad c:\docker-build\dockerfile.dockerfile
# Paste this into docker file -> [LINK]

# startup.ps1 is used to present container\hardware information on the home page.
# We bake this into the image.  Its used to get the computer information after the container is created.  
notepad c:\docker-build\startup.ps1
# Paste this into startup.ps1 file -> [LINK]

#Build image from docker file and test pod
#The base image referenced in the DockerFile and website files will take some time to download ->  mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022

# NOTE: Pull the Base image first for a faster build.  The images are ≈ 4.5GB 
docker pull mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022


cd C:\docker-build
docker build -f dockerfile.dockerfile -t custom-iis-site-with-microk8s-ws2022:2.0 .

#remove the container if needed
# docker rmi custom-iis-site-with-microk8s:2.0 --force
# docker rmi mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022

#Check for the custom-iis-azure-demo:2.0 image
docker images

# Create a container from 
docker run --rm -d -p 8080:80 --name test-iis01 custom-iis-site-with-microk8s-ws2022:2.0
docker exec test-iis01 powershell -Command "ipconfig"
docker exec -it test-iis01 powershell
# Remove Test Container
#get container name
docker ps -a
#remove 
docker rm -f test-iis01
# 2. Same thing but more explicit
docker container rm test-iis01 --force 

#Push Image to hub.docker.com - We will use a .ymal file to pull the image later
# you need an account at hub.docker.com.  
# Use your the user name of your hub.docker.com account
docker login -u username01
# Tag image
docker tag custom-iis-site-with-microk8s-ws2022:2.0 mooselover/custom-iis-site-with-microk8s-ws2022:2.0
# Check Image details like RepoTags
docker image inspect custom-iis-site-with-microk8s-ws2022:2.0 
docker image inspect mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022 
# When you create a new repository on Docker Hub by pushing an image (without explicitly creating it first as private), Docker Hub defaults to public.
# Use Tag when pushing!
# docker push yourdockerhubusername/custom-iis-site-with-microk8s-ws2022
docker push mooselover/custom-iis-site-with-microk8s-ws2022:2.0
docker search mooselover/custom-iis-site-with-microk8s-ws2022:2.0
docker pull mooselover/custom-iis-site-with-microk8s-ws2022:2.0
https://hub.docker.com/r/mooselover/custom-iis-site-with-microk8s-ws2022/tags


# ===============================================================================
# Step 4 -Conifgure Windows Server to be a Micro-k8s Worker Node
#         Join Windows Worker Node to micro-k8s cluster.  
# ===============================================================================
# Check Dependencies
Get-WindowsFeature | ? -Property name -like *hyper*
Get-WindowsFeature | ? -Property name -like *container*
Get-ComputerInfo | Select-Object OsName, OsVersion, OsBuildNumber

# Install the containerd container runtime. The machine might restart during this operation.
Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-ContainerdRuntime/install-containerd-runtime.ps1" -o install-containerd-runtime.ps1
.\install-containerd-runtime.ps1

# Create directory c:\k, create the kubeconfig file c:\k\config. After creating, open the file with notepad, paste the contents of the kubeconfig file of the MicroK8s cluster and save.
mkdir c:\k
New-Item c:\k\config
#Serve up config file from "micro-k8s" the linux control plane node with python
sudo python3 -m http.server --directory ~/.kube 8080

#WINDOWS NODE Download config to "micro-k8s-node01"
Invoke-WebRequest -Uri http://192.168.11.10:8080/config -OutFile "C:\k\config"
Get-Content c:\k\config

# Install Calico
# Retrieve the install-calico-windows.ps1 script from the Calico GitHub releases page. NOTE: do not worry about the calico version in the URL, we will pick the Calico version to install later.
Invoke-WebRequest -Uri https://github.com/projectcalico/calico/releases/download/v3.25.1/install-calico-windows.ps1 -OutFile c:\k\install-calico-windows.ps1

# Download Calico and Kubernetes binaries using the following command (replace 1.27.1 with the Kubernetes version and 3.25.0 with the Calico version running in the cluster):
New-Item -ItemType Directory -Force "C:\Program Files\containerd\bin\cni\bin" 
New-Item -ItemType Directory -Force "C:\Program Files\containerd\bin\cni\conf"
# c:\k\install-calico-windows.ps1 -ReleaseBaseURL "https://github.com/projectcalico/calico/releases/download/v3.29.3" -ReleaseFile "calico-windows-v3.29.3.zip" -KubeVersion "1.33.9" -DownloadOnly "yes" -ServiceCidr "10.152.183.0/24" -DNSServerIPs "10.152.183.10"
# IMPORTANT - Check KubeVersion on Control Plane Node-> sudo microk8s kubectl get nodes  or sudo microk8s version
# This part take a few moments
powershell -NoProfile -ExecutionPolicy Bypass -File C:\k\install-calico-windows.ps1 `
  -ReleaseBaseURL "https://github.com/projectcalico/calico/releases/download/v3.29.3" `
  -ReleaseFile    "calico-windows-v3.29.3.zip" `
  -KubeVersion    "1.33.9" `
  -ServiceCidr    "10.152.183.0/24" `
  -DNSServerIPs   "10.152.183.10"


# Configure the CNI bin and configuration directories and then install the Calico services. 
# If the vSwitch is not yet created, this will temporarily affect network connectivity for a few seconds.
$ENV:CNI_BIN_DIR="c:\program files\containerd\cni\bin"
$ENV:CNI_CONF_DIR="c:\program files\containerd\cni\conf"

# Running c:\k\install-calico-windows.ps1 creates c:\calicowindows\install-calico.ps1, c:\calicowindows\kubernetes\install-kube-services.ps1 and c:\calicowindows\start-calico.ps1
# c:\calicowindows\install-calico.ps1 is run when you run C:\k\install-calico-windows.ps1


#Run install Script
c:\calicowindows\install-calico.ps1
#Start Calico
c:\calicowindows\start-calico.ps1

#MAKE SURE FILES WERE PLACED
dir "C:\Program Files\containerd\cni\bin"
dir "C:\Program Files\containerd\cni\conf"

# If successful, the output should look like this:
# Starting Calico...
# This may take several seconds if the vSwitch needs to be created.
# Waiting for Calico initialisation to finish...
# Waiting for Calico initialisation to finish...StoredLastBootTime , CurrentLastBootTime 5/21/2023 8:21:24 AM
# Waiting for Calico initialisation to finish...StoredLastBootTime , CurrentLastBootTime 5/21/2023 8:21:24 AM
# Calico initialisation finished.
# Done, the Calico services are running:

# Status   Name               DisplayName
# ------   ----               -----------
# Running  CalicoFelix        Calico Windows Agent
# Running  CalicoNode         Calico Windows Startup

# Install Kubernetes services (kubelet and kube-proxy):
c:\calicowindows\kubernetes\install-kube-services.ps1

# Add a firewall rule for incoming connections to the Windows kubelet node service. This is for kubectl logs and kubectl exec commands to work with pods running in Windows nodes:
New-NetFirewallRule -Name 'Kubelet-In-TCP' -DisplayName 'Kubelet (node)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 10250

# Configure the network adapter name expected by the kubelet service.  
# Run ipconfig to retrieve the IP configuration of the machine’s network adapters.
ipconfig
# Update c:\calicowindows\kubernetes\kubelet-service.ps1 -> [string]$InterfaceName="vEthernet (Ethernet)"
notepad c:\calicowindows\kubernetes\kubelet-service.ps1

# Start Kubernetes services.  
# At this point the windows node joins k8s cluster!!
Start-Service kubelet
Start-Service kube-proxy

Restart-Service containerd
Restart-Service kubelet -Force
# Check the windows node has joined on the control plane node.  
#Note it take a few moments for Status to go from 'Not Ready' to 'Ready'
# it usually takes 5-15+ minutes
sudo microk8s kubectl get nodes

#if it takes longer check 
sudo microk8s kubectl describe node k8s-node03

# Start a test pod on the Windows node and wait for it to come up.
# Warning this takes time to download the image.  
# It can take 40 mins at ≈ 50 Mbps
# Pull the base image first for a faster build.  The images are ≈ 4.5GB

# WARNING: If you see this error run the command again -> ctr: failed to copy: read tcp 192.168.11.12:50707->150.171.70.10:443: wsarecv: An existing connection was forcibly closed by the remote host.

& "C:\Program Files\containerd\bin\ctr.exe" -n k8s.io images pull mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022

#check if image was pulled
& "C:\Program Files\containerd\bin\ctr.exe" -n k8s.io images ls

# Pull the custom image will now pull faster since the base image is cached.  
# This is the image we will use for our IIS pods in the next step.
& "C:\Program Files\containerd\bin\ctr.exe" -n k8s.io images pull docker.io/mooselover/custom-iis-site-with-microk8s-ws2022:2.0

#check if image was pulled
& "C:\Program Files\containerd\bin\ctr.exe" -n k8s.io images ls



# ===============================================================================
# Step 5 -Deploy IIS Pods
#         Conigure Control Plane Node to deploy pods with containers built from the custom docker image
#         Containers are built from custom docker image hosted on hub.docker.com.
#         This configures a NodePort service to access the website.  
#         We will change this to a LoadBalancer service in the next step.
# ===============================================================================

# Setup config file
##################################
# NOTE: Replicas is the number of pods.  
sudo nano iis-simple.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis-simple
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: iis
  template:
    metadata:
      labels:
        app: iis
    spec:
      nodeSelector:
        kubernetes.io/os: windows
      containers:
      - name: iis
        image: mooselover/custom-iis-site-with-microk8s-ws2022:2.0
        imagePullPolicy: Always
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: iis-service
  namespace: default
spec:
  type: NodePort
  selector:
    app: iis
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080


#
#

# Apply the .ymal config
sudo microk8s kubectl apply -f iis-simple.yaml

# Check Pods
sudo microk8s kubectl get pods -o wide -w

# Look for iis-service → PORT(S) includes 80:30080/TCP
sudo microk8s kubectl get svc

# The pull phase can take about 30–34 minutes from the initial apply
sudo microk8s kubectl describe pod iis-simple-6cc6f5549d-dvqms

# Check website by port
http://192.168.88.10:30080

#Scale Deploymnet
sudo microk8s kubectl scale deployment/iis-simple --replicas=6


# Check
sudo microk8s kubectl get svc

#check
sudo microk8s kubectl get svc iis-service -o yaml | grep -A5 type:



# ===============================================================================
# Step 6 -Configure Deployment to use metallb LoadBalancer instead of NodePort
# ===============================================================================
###############SWTICH#######################

# 1. Delete the current Deployment (this kills all pods)
sudo microk8s kubectl delete deployment iis-simple --grace-period=0 --force

# 2. Clean up any leftover pods/services (just in case)
sudo microk8s kubectl delete pods --selector=app=iis --grace-period=0 --force
sudo microk8s kubectl delete svc iis-service  # if it complains "not found" that's fine
sudo microk8s kubectl delete pod iis-simple-6cc6f5549d-8fdw7 --grace-period=0 --force


# Enable metallb LoadBalancer 
 sudo microk8s enable metallb:192.168.11.100-192.168.11.150
#Check metallb
sudo microk8s kubectl -n metallb-system get pods -o wide
# Configure Deployment to use metalb LoadBalancer
sudo nano iis-simple.yaml
# NOTE: Replicas is the number of pods.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis-simple
  namespace: default
spec:
  replicas: 9
  selector:
    matchLabels:
      app: iis
  template:
    metadata:
      labels:
        app: iis
    spec:
      nodeSelector:
        kubernetes.io/os: windows
      containers:
      - name: iis
        image: mooselover/custom-iis-site-with-microk8s-ws2022:2.0
        imagePullPolicy: Always              # Force pull every time (breaks cache)
        ports:
        - containerPort: 80
        # Optional: readiness probe (helps if startup.ps1 takes time)
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: iis-service
  namespace: default
spec:
  type: LoadBalancer          # <-- Changed from NodePort
  selector:
    app: iis
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80



#
sudo microk8s kubectl apply -f iis-simple.yaml
sudo microk8s kubectl get svc iis-service -w

sudo microk8s kubectl get pods -o wide -w

sudo microk8s kubectl describe pod iis-simple-6f577b79d8-87pjh
#Scale Deploymnet
sudo microk8s kubectl scale deployment/iis-simple --replicas=12


# Check
sudo microk8s kubectl get svc

#check
sudo microk8s kubectl get svc iis-service -o yaml | grep -A5 type:





