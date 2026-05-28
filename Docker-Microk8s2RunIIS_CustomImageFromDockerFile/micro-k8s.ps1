# =============================================================================
# K8s Lab - Micro k8s cluster to run IIS Pods to serve up a custom website
# =============================================================================
# Author:   Mark Kruse
# Purpose:  Create a Micro k8s cluster to run IIS Pods to serve up a custom website
# Location: Anchorage, Alaska lab environment
# =============================================================================
# =========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-VMQuickCreate-GoldenImages-DiskFunctions/HyperV%20Lab%20Creation%20and%20Disk%20Functions.ps1
# =========================================================================================================================================================
# =========================================================================================================================================================
# Recommended: How to create Hyper-V Windows Server Router\DHCP Server
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/ADDS-GPO-EntraConnect-LinuxADJoin/RRAS%20Setup.ps1
# ==================================================================================================================
# Note: For this Lab You can an External Hyper-V Switch connected to all VMs, instead of Hyper-V router
# ==================================================================================================================
#  Why Containers Are More Efficient

# No duplicate kernels → less overhead.  Smaller size → less disk usage
# Faster spin-up → milliseconds vs minutes
# Better resource usage → higher density (more apps per server)
# VMs = separate houses (each with its own plumbing, electricity)
# Containers = apartments in the same building (shared infrastructure)

# Containers share the kernel, so:  They are less isolated than VMs.  Security boundaries are weaker (but still strong with proper config)
# Containers → process-level isolation
# VMs → hardware/OS-level isolation

# ===============================================================================
# # Prerequisites   Custom Built Image from Docker file to build custom website
#                   [Link] -> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/Docker-Microk8s2RunIIS_CustomImageFromDockerFile/BuildAndPushImagefromDockerFile.ps1
# ===============================================================================


# ===============================================================================
# Step 1 -Create Control Plane Node and Windows Worker Nodes virtual machines
#         Expose Virtualization Extensions on Windows Worker Nodes      
# ===============================================================================
# Control Plane Node
$iso = "C:\ISO\ubuntu-26.04-live-server-amd64.iso"
New-Lab_VM -VMNames micro-k8s -HyperVSwitch Linux-NET -RAM 2GB -ISOPath $iso
Stop-VM -VMName micro-k8s -Force -Verbose *>&1
Set-VMFirmware -VMName micro-k8s -EnableSecureBoot off -Verbose *>&1
Start-VM -VMName micro-k8s -Verbose *>&1


# Create Windows Worker Nodes
# Rename Computer Names on Windows Worker Nodes
# Expose Virtualization Extensions 
# Install Required Windows Features -> Hyper-V and Containers

# micro-k8s-node01
New-Lab_VM -VMNames "micro-k8s-node01" -HyperVSwitch Linux-Net -GeneralizedImageCore
Stop-VM -VMName $node.VMName -Force -Verbose *>&1 
Start-Sleep 1 
Set-VMProcessor -VMName $node.VMName -ExposeVirtualizationExtensions $true -Verbose *>&1
Start-VM -VMName $node.VMName -Verbose *>&1
Get-VMProcessor -VMName $node.VMName | Select-Object VMName, ExposeVirtualizationExtensions
# Inside Guest OS
$WindowsNode = "k8s-node01"
#Rename Worker Node
Rename-Computer -NewName $WindowsNode -Verbose *>&1
# Install Required Windows Features
Install-WindowsFeature -Name Containers, Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart

# micro-k8s-node02
New-Lab_VM -VMNames "micro-k8s-node02" -HyperVSwitch Linux-Net -GeneralizedImageCore
Stop-VM -VMName $node.VMName -Force -Verbose *>&1 
Start-Sleep 1 
Set-VMProcessor -VMName $node.VMName -ExposeVirtualizationExtensions $true -Verbose *>&1
Start-VM -VMName $node.VMName -Verbose *>&1
Get-VMProcessor -VMName $node.VMName | Select-Object VMName, ExposeVirtualizationExtensions
# Inside Guest OS
$WindowsNode = "k8s-node02"
#Rename Worker Node
Rename-Computer -NewName $WindowsNode -Verbose *>&1
# Install Required Windows Features
Install-WindowsFeature -Name Containers, Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart

# micro-k8s-node03
New-Lab_VM -VMNames "micro-k8s-node03" -HyperVSwitch Linux-Net -GeneralizedImageCore
Stop-VM -VMName $node.VMName -Force -Verbose *>&1 
Start-Sleep 1 
Set-VMProcessor -VMName $node.VMName -ExposeVirtualizationExtensions $true -Verbose *>&1
Start-VM -VMName $node.VMName -Verbose *>&1
Get-VMProcessor -VMName $node.VMName | Select-Object VMName, ExposeVirtualizationExtensions
# Inside Guest OS
$WindowsNode = "k8s-node03"
#Rename Worker Node
Rename-Computer -NewName $WindowsNode -Verbose *>&1
# Install Required Windows Features
Install-WindowsFeature -Name Containers, Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart

# micro-k8s-node04
New-Lab_VM -VMNames "micro-k8s-node04" -HyperVSwitch Linux-Net -GeneralizedImageCore
Stop-VM -VMName $node.VMName -Force -Verbose *>&1 
Start-Sleep 1 
Set-VMProcessor -VMName $node.VMName -ExposeVirtualizationExtensions $true -Verbose *>&1
Start-VM -VMName $node.VMName -Verbose *>&1
Get-VMProcessor -VMName $node.VMName | Select-Object VMName, ExposeVirtualizationExtensions
# Inside Guest OS
$WindowsNode = "k8s-node04"
#Rename Worker Node
Rename-Computer -NewName $WindowsNode -Verbose *>&1
# Install Required Windows Features
Install-WindowsFeature -Name Containers, Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Verbose *>&1 -Restart

#Check Virtualization Extensions are exposed
$VMs = Get-VM | Where-Object -Property VMName -Like *micro-k8s-node0*
foreach($VM in $VMs){
  Get-VMProcessor -VMName $($VM.Name) | Select-Object VMName, ExposeVirtualizationExtensions
}

# ===============================================================================
# Step 3 -Configure Control Plane
#         Install Micro K8s and configure server allow for Windows Nodes to join.  
# ===============================================================================
$controlPlaneIP = "192.168.11.61" # UPDATE IP TO YOUR LINUX BOXES IP!!

ssh admin01@$controlPlaneIP
# Install Micro-K8s
# sudo snap install microk8s --classic --channel=1.35/stable
sudo snap install microk8s --classic
sudo microk8s start
sudo microk8s status
sudo microk8s kubectl version
# After installing MicroK8s and adding "admin01" to "microk8s" group, you must refresh your shell:
sudo usermod -a -G microk8s admin01
id
exit
ssh admin01@$controlPlaneIP
# Check Group Membership
id 
#Check Status
sudo microk8s status
#Check kubectl version
sudo microk8s kubectl version

#Wait for Kubernetes to be ready

# Enable useful MicroK8s add-ons
# sudo microk8s enable dns dashboard storage ingress metallb:192.168.88.100-192.168.88.200

# Enable DNS Storage, hostpath-storage and Dashboard
# DNS allows containers (pods) to find each other by name instead of IP. (Most Likely On Already)
sudo microk8s enable dns 
# Hostpath-Storage Creates a simple storage system using your machine’s local disk.
sudo microk8s enable hostpath-storage

#Check Status
sudo microk8s status

# Check kubectl pods
# WARNING, you need to wait untill all these pods are up
sudo microk8s kubectl get pods -A
#Use kubectl (MicroK8s bundles it)


#Alias for convenience (add to ~/.bashrc):
# alias kubectl='microk8s kubectl'

# Determine the exact version of Kubernetes running in the cluster, e.g. 1.27.1. You can use the following command:
sudo microk8s kubectl get node -o wide
# containerd://1.7.27


# Installs the Kubernetes web UI (Dashboard)
# Enable Headlamp (much better than the old dashboard)
# 1. Add Helm repo
microk8s helm3 repo add headlamp https://kubernetes-sigs.github.io/headlamp/

microk8s helm3 repo update

# 2. Install it
microk8s helm3 install headlamp headlamp/headlamp --namespace kube-system --create-namespace

# Auth Token
microk8s kubectl create token headlamp -n kube-system --duration=8760h

# Start port forwarding (leave this terminal window open)
# If you see this error, wait 5 mins and try again -> "error: unable to forward port because pod is not running. Current status=Pending"
microk8s kubectl port-forward -n kube-system svc/headlamp 8080:80 --address 0.0.0.0

# Access from Web Browser
$controlPlaneIP = "192.168.11.61"
http://192.168.11.61:8080/

# Determine the exact version of Calico running in the MicroK8s cluster, e.g. 3.25.0. For this, you can inspect the image used by the calico-node containers:
sudo microk8s kubectl get ds/calico-node -n kube-system -o jsonpath='{.spec.template.spec.containers[?(.name=="calico-node")].image}{"\n"}'
#OUTPUT ->  docker.io/calico/node:v3.29.3
CALICO_VERSION="3.29.3"
echo $CALICO_VERSION
# Generate a kubeconfig file for the MicroK8s cluster. You will need this to run calicoctl commands, and later copy it to the Windows node.
mkdir -p ~/.kube
sudo chown -f -R admin01 ~/.kube
sudo microk8s config > ~/.kube/config
sudo cat ~/.kube/config

# Check Control Plane Node.  It should have a "Ready" Status
sudo microk8s kubectl get nodes




# Even though your cluster already has Calico running, Kubernetes doesn’t give you direct control over Calico-specific settings.
#  calicoctl lets you manage Calico directly.  calicoctl is the official command-line tool for managing Calico (the networking and network security solution for Kubernetes).
CALICO_VERSION="3.29.3"
curl -L https://github.com/projectcalico/calico/releases/download/v$CALICO_VERSION/calicoctl-linux-amd64 -o calicoctl
chmod +x ./calicoctl

# Check calicoctl version and nodes
./calicoctl version
# This tells you how Calico is operating:
# k8s → Running inside Kubernetes 
# bgp → Uses BGP (network routing protocol between nodes)(Border Gateway Protocol)
# kdd → Kubernetes Datastore Driver (stores config in Kubernetes API) 
# Your networking is Kubernetes-native
# Calico is managing routing between pods/nodes
./calicoctl version

# Calico node name
./calicoctl get nodes

# This command changes how Calico assigns IP addresses to pods
# Main purpose: Forces each node to use only its own IP address block
# It improves networking stability and performance by ensuring pods on a node only get IP addresses from that node's own IP block, 
# which reduces cross-node traffic, fixes routing issues, and is often required for proper LoadBalancer / MetalLB / NetworkPolicy behavior in Calico.

./calicoctl ipam configure --strictaffinity=true --allow-version-mismatch
# NOTE:
# Without strict affinity (default behavior), nodes can borrow IP addresses from other nodes.
# This works fine for Linux-only clusters
# BUT causes problems in mixed environments

# With strict affinity = true, Each node can ONLY use its own assigned IP range.  No borrowing from other nodes
# Required for Windows nodes.   Without strict affinity: Linux nodes may grab IPs meant for Windows nodes.  
./calicoctl ipam show --show-configuration


# ===============================================================================
# Step 4 -Conifgure Windows Server to be a Micro-k8s Worker Node
#         Join Windows Worker Node to micro-k8s cluster.  
# 
# ===============================================================================

# ====================================
# Serve up config file from "micro-k8s" the linux control plane node with python
# ====================================
sudo python3 -m http.server --directory ~/.kube 8081

# ====================================
# On the Windows Node 
# ====================================
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
#WINDOWS NODE Download config to "micro-k8s-node01"
$linuxIP = "192.168.11.61" # UPDATE IP!!
$uri = "http://" + $linuxIP + ":8081/config"
Invoke-WebRequest -Uri $uri -OutFile C:\k\config
Get-Content c:\k\config

# Install Calico
# Retrieve the install-calico-windows.ps1 script from the Calico GitHub releases page. NOTE: do not worry about the calico version in the URL, we will pick the Calico version to install later.
Invoke-WebRequest -Uri https://github.com/projectcalico/calico/releases/download/v3.25.1/install-calico-windows.ps1 -OutFile C:\k\install-calico-windows.ps1

# Create File Paths needed for C:\k\install-calico-windows.ps1
New-Item -ItemType Directory -Force "C:\Program Files\containerd\bin\cni\bin" 
New-Item -ItemType Directory -Force "C:\Program Files\containerd\bin\cni\conf"
# Set Variables for C:\k\install-calico-windows.ps1
$ENV:CNI_BIN_DIR="c:\program files\containerd\cni\bin"
$ENV:CNI_CONF_DIR="c:\program files\containerd\cni\conf"
# c:\k\install-calico-windows.ps1 -ReleaseBaseURL "https://github.com/projectcalico/calico/releases/download/v3.29.3" -ReleaseFile "calico-windows-v3.29.3.zip" -KubeVersion "1.33.9" -DownloadOnly "yes" -ServiceCidr "10.152.183.0/24" -DNSServerIPs "10.152.183.10"
# IMPORTANT - Check KubeVersion on Control Plane Node-> sudo microk8s kubectl get nodes  or sudo microk8s version
# This part take a few moments
powershell -NoProfile -ExecutionPolicy Bypass -File C:\k\install-calico-windows.ps1 `
  -ReleaseBaseURL "https://github.com/projectcalico/calico/releases/download/v3.29.3" `
  -ReleaseFile    "calico-windows-v3.29.3.zip" `
  -KubeVersion    "1.33.9" `
  -ServiceCidr    "10.152.183.0/24" `
  -DNSServerIPs   "10.152.183.10"

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



# Add a firewall rule for incoming connections to the Windows kubelet node service. This is for kubectl logs and kubectl exec commands to work with pods running in Windows nodes:
New-NetFirewallRule -Name 'Kubelet-In-TCP' -DisplayName 'Kubelet (node)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 10250

# Install Kubernetes services (kubelet and kube-proxy):
c:\calicowindows\kubernetes\install-kube-services.ps1



# Configure the network adapter name expected by the kubelet service.  
# Run ipconfig to retrieve the IP configuration of the machine’s network adapters.
ipconfig
# Update c:\calicowindows\kubernetes\kubelet-service.ps1
# EXAMPLE -> [string]$NodeIp="192.168.11.57",
# EXAMPLE -> [string]$InterfaceName="vEthernet (Ethernet)"
notepad c:\calicowindows\kubernetes\kubelet-service.ps1

# Start Kubernetes services.  
# At this point the windows node joins k8s cluster!!
Get-Service kubelet
Get-Service kube-proxy
Start-Service kubelet
Start-Service kube-proxy

Restart-Service containerd
Restart-Service kubelet -Force
# Check the windows node has joined on the control plane node.  
#Note it take a few moments for Status to go from 'Not Ready' to 'Ready'
# it usually takes 5-15+ minutes
sudo microk8s kubectl get nodes -o wide

#if it takes longer check 
sudo microk8s kubectl describe node k8s-node01

# ===============================================================================
# Step 5 -Pull Image to each worker node
#         Deploy IIS Pods
#         Conigure Control Plane Node to deploy pods with containers built from the custom docker image
#         Containers are built from custom docker image hosted on hub.docker.com.
#         This configures a NodePort service to access the website.  
#         We will change this to a LoadBalancer service in the next step.
# ===============================================================================
# It can take 40 mins at ≈ 50 Mbps
# Pull the base image first for a faster build.  The Image needs to be pulled to all Nodes!!  The images are ≈ 4.5GB

# WARNING: If you see this error run the command again -> ctr: failed to copy: read tcp 192.168.11.12:50707->150.171.70.10:443: wsarecv: An existing connection was forcibly closed by the remote host.

# Pull base image for faster builds
& "C:\Program Files\containerd\bin\ctr.exe" -n k8s.io images pull mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2025

#check if image was pulled
& "C:\Program Files\containerd\bin\ctr.exe" -n k8s.io images ls

# Pull the custom image will now pull faster since the base image is cached.  
# This is the image we will use for our IIS pods in the next step.
& "C:\Program Files\containerd\bin\ctr.exe" -n k8s.io images pull docker.io/mooselover/custom-iis-site-with-microk8s-ws2025:1.0

#check if image was pulled
& "C:\Program Files\containerd\bin\ctr.exe" -n k8s.io images l

& "C:\Program Files\containerd\bin\ctr.exe" -n k8s.io images ls | findstr mooselover
# Setup config file
##################################
# NOTE: Replicas is the number of pods.  
sudo nano iis-simple.yaml
---
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
      hostname: iis-mainsite-akwild               # Computer name inside Windows (max 15 chars)
      subdomain: iis-service         # For internal DNS
      nodeSelector:
        kubernetes.io/os: windows
      containers:
      - name: iis
        image: mooselover/custom-iis-site-with-microk8s-ws2025:1.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80

        # Startup Probe - Very patient during initial boot
        startupProbe:
          httpGet:
            path: /
            port: 80
          failureThreshold: 30        # Allow up to 5 minutes of startup time
          periodSeconds: 10
          timeoutSeconds: 10

        # Readiness Probe - After startup is complete
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 60
          periodSeconds: 15
          timeoutSeconds: 10
          failureThreshold: 12
          successThreshold: 1

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
# ==================================
# Apply the .ymal config
# ==================================

# Wait ≈ 10-15 mins to see pods come up after applying .yaml
sudo microk8s kubectl apply -f iis-simple.yaml

# Check Pods - It takes time for them to come up - 5-15 mins
sudo microk8s kubectl get pods -o wide 
POD=iis-simple-7876d9c966-5bwg5
# Use your Pod name
sudo microk8s kubectl describe pod $POD
#check Containers
microk8s kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].name}" | tr ' ' '\n'

# Add IP.3 = 192.168.11.32
# # $WindowsNodeIP = 192.168.11.32
# sudo nano /var/snap/microk8s/current/certs/csr.conf.template
# sudo microk8s refresh-certs --cert server.crt
# sudo microk8s stop
# sudo microk8s start

microk8s kubectl exec -it iis-simple-9c47dc66-fhr86 --insecure-skip-tls-verify --container iis -- powershell.exe
# Look for iis-service → PORT(S) includes 80:30080/TCP
sudo microk8s kubectl get svc

# The pull phase can take about 30–34 minutes from the initial apply
sudo microk8s kubectl describe pod iis-simple-9c47dc66-2vnps
$linuxIP = "192.168.11.61"
# Check website by port
http://192.168.11.61:30080

#Scale Deploymnet
sudo microk8s kubectl scale deployment/iis-simple --replicas=6


# Check
sudo microk8s kubectl get svc

#check
sudo microk8s kubectl get svc iis-service -o yaml | grep -A5 type:

# access containers via command line
# microk8s kubectl exec -it <pod-name> -- /bin/sh
microk8s kubectl exec -it <pod-name> -- powershell


# ===============================================================================
# Step 6 -Configure Deployment to use metallb LoadBalancer instead of NodePort
# ===============================================================================
###############SWTICH#######################

# 1. Delete the current Deployment (this kills all pods)
sudo microk8s kubectl delete deployment iis-simple --grace-period=0 --force

# 2. Clean up any leftover pods/services (just in case)
sudo microk8s kubectl delete pods --selector=app=iis --grace-period=0 --force
sudo microk8s kubectl delete svc iis-service  # if it complains "not found" that's fine

#Delete any other pods from deployment
sudo microk8s kubectl get pods -o wide 
sudo microk8s kubectl delete pod iis-simple-6cc6f5549d-8fdw7 --grace-period=0 --force

sudo microk8s kubectl get pods -o wide 

# Enable metallb LoadBalancer 
 sudo microk8s enable metallb:192.168.11.100-192.168.11.150
#Check metallb
sudo microk8s kubectl -n metallb-system get pods -o wide
# Configure Deployment to use metalb LoadBalancer
sudo nano iis-metallb.yaml
# NOTE: Replicas is the number of pods.
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis
  namespace: default
spec:
  replicas: 12
  selector:
    matchLabels:
      app: iis
  template:
    metadata:
      labels:
        app: iis
    spec:
      hostname: iis-mainsite-akwild                # Computer name inside Windows (max 15 chars)
      subdomain: iis-service         # For internal DNS
      nodeSelector:
        kubernetes.io/os: windows
      containers:
      - name: iis
        image: mooselover/custom-iis-site-with-microk8s-ws2025:1.0
        imagePullPolicy: IfNotPresent              
        ports:
        - containerPort: 80

        # Startup Probe - Very patient for slow Windows IIS startup
        startupProbe:
          httpGet:
            path: /
            port: 80
          failureThreshold: 30        # Allows up to ~5 minutes for startup
          periodSeconds: 10
          timeoutSeconds: 10

        # Readiness Probe - After startup completes
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 60
          periodSeconds: 15
          timeoutSeconds: 10
          failureThreshold: 12
          successThreshold: 1

---
apiVersion: v1
kind: Service
metadata:
  name: iis-service
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: iis
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80



#
sudo microk8s kubectl apply -f iis-metallb.yaml
sudo microk8s kubectl get svc iis-service -w

sudo microk8s kubectl get pods -o wide
POD=iis-9956868-b64pj
sudo microk8s kubectl describe pod $POD
#Scale Deploymnet at a MEGA SCALE!
sudo microk8s kubectl scale deployment/iis --replicas=21


# Check
sudo microk8s kubectl get svc

#check
sudo microk8s kubectl get svc iis-service -o yaml | grep -A5 type:





# Delete both the deployment and the service
sudo microk8s kubectl delete deployment iis --grace-period=0 --force
sudo microk8s kubectl delete service iis-service
#clean stuck pods
sudo microk8s kubectl get pods -l app=iis -o name | xargs -I {} sudo microk8s kubectl delete {} --force --grace-period=0