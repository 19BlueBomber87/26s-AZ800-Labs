# =============================================================================
# Hyper-V Lab Creation - k8s Cluster to run nginx pods to serve up a custom website
# =============================================================================
# Author:   Mark Kruse
# Purpose:  k8s Cluster to run nginx pods to serve up a custom website
# Location: Anchorage, Alaska lab environment
# =============================================================================
# =========================================================================================================================================================
# Use link below to get 'New-Lab_VM' command
# https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/HyperV-QuickCreate-GoldenImages/AZ-800Celebrate-HyperV%20Creation%20and%20Disk%20Functions.ps1
# =========================================================================================================================================================




# ===================================================
# Step 1 - Configure k8s control plane node
# ===================================================

#Create VM for control plane
New-Lab_VM -VMNames k8s -HyperVSwitch Linux-Net -RAM_GB 2GB -ISOPath C:\ISO\ubuntu-24.04.3-live-server-amd64.iso
Stop-VM -VMName k8s -Force -Verbose *>&1
Set-VMFirmware -VMName k8s -EnableSecureBoot Off
Start-VM -VMName k8s -Verbose *>&1


# initialconfig.sh -> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/k8s2ServeCustomeNginxWebsite/initialConfig.sh
sudo nano initialConfig.sh
# Copy and paste initialConfig.sh for Git Hub, on control plane node.  
#run initial config script
sudo bash initialConfig.sh



# ===================================================
# Step 2 - Initialize The Cluster and configure calico network plugin on control plane node
# ===================================================

### Pull images needed for kubeadm init (optional but speeds up control plane startup)
sudo kubeadm config images pull 
sudo crictl images --verbose
sudo crictl images

#initialize control plane (with pod network CIDR for Calico)
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 

### Set up kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install the Tigera operator + CRDs
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/tigera-operator.yaml

# (optional but good practice) Wait a few seconds for the operator to be ready
sleep 30
kubectl -n tigera-operator wait --for=condition=Available deployment/tigera-operator --timeout=120s

# Install Calico itself via the Installation custom resource
# Your --pod-network-cidr=192.168.0.0/16 matches Calico's default IPPool, so the unmodified manifest works fine
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/custom-resources.yaml


watch kubectl get nodes


# Core pods in kube-system — make sure all are running
kubectl get pods -n kube-system -o wide

# Calico-specific pods (in calico-system namespace) — make sure all are running
kubectl get pods -n calico-system

# Tigera operator status (should show Available: True for calico and others)
kubectl get tigerastatus

# Overall cluster info
kubectl cluster-info
kubectl get all -A

# All nodes should be Ready (just one, the control plane node in this case)
kubectl get nodes -o wide


# ===================================================
# Step 3 - Configure Linux-Worker Node
# ===================================================

New-Lab_VM -VMNames k8s-node01 -HyperVSwitch Linux-Net -ISOPath C:\ISO\ubuntu-24.04.3-live-server-amd64.iso -RAM_GB 2GB

Stop-VM -VMName k8s-node01 -Force -Verbose *>&1
Set-VMFirmware -VMName k8s-node01 -EnableSecureBoot Off
Start-VM -VMName k8s-node01 -Verbose *>&1

New-Lab_VM -VMNames k8s-node02 -HyperVSwitch Linux-Net -ISOPath C:\ISO\ubuntu-24.04.3-live-server-amd64.iso -RAM_GB 2GB

Stop-VM -VMName k8s-node02 -Force -Verbose *>&1
Set-VMFirmware -VMName k8s-node02 -EnableSecureBoot Off
Start-VM -VMName k8s-node02 -Verbose *>&1

New-Lab_VM -VMNames k8s-node01 -HyperVSwitch Linux-Net -ISOPath C:\ISO\ubuntu-24.04.3-live-server-amd64.iso -RAM_GB 2GB

Stop-VM -VMName k8s-node01 -Force -Verbose *>&1
Set-VMFirmware -VMName k8s-node01 -EnableSecureBoot Off
Start-VM -VMName k8s-node01 -Verbose *>&1

  
# initialconfig.sh -> https://github.com/19BlueBomber87/26s-AZ800-Labs/blob/main/k8s2ServeCustomeNginxWebsite/initialConfig.sh
sudo nano initialConfig.sh
# Copy and paste initialConfig.sh for Git Hub on worker nodes.
#run initial config script
sudo bash initialConfig.sh

#CHECK
kubeadm version
kubectl version --client
kubelet --version

# Get Join command from control plane (run this on control plane and paste the output here to run on worker):
kubeadm token create --print-join-command
# EXAMPLE TO RUN ON WORKER NODE: sudo kubeadm join 192.168.11.17:6443 --token z3dsf2.yvwfggorjpd9tswo --discovery-token-ca-cert-hash sha256:ea6f1ff344176d7667df10285945bca7eec1aeb8fa995cb85d15a5631a819be8


# Verify the worker node joined
# Wait a moment and you see node status change to "Ready" on control plane when worker joins.  
kubectl get nodes
kubectl describe node k8s 
kubectl describe node k8s-node01


#Remove Nodes from the cluster during testing
kubectl drain k8s-node02 --delete-emptydir-data --force --ignore-daemonsets
kubectl delete node k8s-node02






















# ===================================================
# Step 3 - Serve up a custom website using nginx pods, with MetalLB for LoadBalancer and Ingress for routing
# ===================================================

#Install MetalLB (for LoadBalancer on bare metal)
# This assigns IPs from your local network to services of type LoadBalancer.
# On your admin machine (where kubectl works)
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml

# Wait for pods ready in metallb-system ns
kubectl get pods -n metallb-system -w 
kubectl describe pod controller-d54bf7b99-vnc8d -n metallb-system

# Double check Calico node pods are healthy before proceeding, as MetalLB speaker runs on each node and needs network ready:
kubectl get pods -A -l k8s-app=calico-node

# Create a ConfigMap to define your IP pool (pick free IPs in your 192.168.11.0/24 subnet, e.g., avoid .18–.21 used by nodes):
# metallb-config.yaml
sudo nano metallb-config.yaml
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: home-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.11.200-192.168.11.220
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: home-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - home-pool
#

# Apply it:
kubectl apply -f metallb-config.yaml

# Step 2: Install NGINX Ingress Controller
# Create the namespace and deploy the controller:
kubectl create namespace ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.3/deploy/static/provider/baremetal/deploy.yaml
# Or latest: replace v1.11.2 with current tag from https://github.com/kubernetes/ingress-nginx/releases

# Wait for ready
kubectl get pods -n ingress-nginx -w
# Patch the service to type LoadBalancer (MetalLB will assign an IP):
kubectl patch svc ingress-nginx-controller -n ingress-nginx --type='json' -p='[{"op": "replace", "path": "/spec/type", "value":"LoadBalancer"}]'
# Check:
kubectl get svc -n ingress-nginx
# Look for EXTERNAL-IP – should be one from your pool, e.g., 192.168.11.200
# If pending > 5 min, check MetalLB logs: kubectl logs -n metallb-system -l app=metallb
# Now your Ingress controller is reachable at that IP on ports 80/443.

# Optional: Pull nginx image on nodes to speed up first pod startup (not required, but good for demos):
sudo crictl pull nginx:alpine
sudo crictl images 
sudo crictl images | grep nginx
# Step 3: Deploy Your Static Site (Quick Git Pull Method – No CI Needed Yet)
# Create these YAMLs in a dir, adjust YOUR_GITHUB_REPO.

sudo nano static-site-custom.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: customize-script
data:
  customize.sh: |
    #!/bin/sh
    set -e

    echo "Starting customization..."

    HOST=$(hostname)
    TODAY=$(date +%m-%d-%Y)
    POD_IP=$(hostname -i | awk '{print $1}')
    CPU=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//') || CPU="Unknown CPU"
    OS_VER="K8s Pod on $(uname -s) $(uname -r)"

    ESC_HOST=$(echo "$HOST" | sed 's/[\/&]/\\&/g')
    ESC_IP=$(echo "$POD_IP" | sed 's/[\/&]/\\&/g')
    ESC_CPU=$(echo "$CPU" | sed 's/[\/&]/\\&/g')
    ESC_OS=$(echo "$OS_VER" | sed 's/[\/&]/\\&/g')

    TARGET_FILE="/html/azurehome.html"
    INDEX_FILE="/html/index.html"

    if [ -f "$TARGET_FILE" ]; then
      echo "Found $TARGET_FILE"
      echo "Running sed replacement..."
      sed -i "s/Custom Heading Size and Font Type/Welcome to K8s <br>Computer Name: $ESC_HOST<br>OS Version: $ESC_OS<br>Date: $TODAY<br>CPU: $ESC_CPU<br>IP: $ESC_IP/g" "$TARGET_FILE"
      echo "sed finished"

      echo "Copying customized file to index.html for Nginx..."
      cp "$TARGET_FILE" "$INDEX_FILE" || { echo "ERROR: Failed to copy to index.html"; exit 1; }
      echo "Customization and copy complete"
    else
      echo "ERROR: $TARGET_FILE does NOT exist after pull-files init"
      ls -la /html/
      exit 1
    fi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-static-site
spec:
  replicas: 3
  selector:
    matchLabels:
      app: custom-site
  template:
    metadata:
      labels:
        app: custom-site
    spec:
      initContainers:
        - name: pull-files
          image: alpine:3.19
          command:
            - /bin/sh
            - -c
          args:
            - |
              set -e
              apk add --no-cache git
              git clone --single-branch --branch main --depth 1 https://github.com/19BlueBomber87/25s-Azure-IaC.git /repo/azure
              git clone --single-branch --branch master --depth 1 https://github.com/19BlueBomber87/toDoApp.git /repo/todo
              mkdir -p /html/jpg
              cp /repo/azure/html/azurehome.html /html/azurehome.html
              cp /repo/azure/html/cert.jpg /html/jpg/cert.jpg
              cp /repo/todo/jpg/*.jpg /html/jpg/ || true
          volumeMounts:
            - name: html-content
              mountPath: /html
            - name: repo-temp
              mountPath: /repo

        - name: customize-html
          image: alpine:3.19
          command:
            - /bin/sh
            - -c
            - sh /scripts/customize.sh
          volumeMounts:
            - name: html-content
              mountPath: /html
            - name: customize-script
              mountPath: /scripts

      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: html-content
              mountPath: /usr/share/nginx/html
              readOnly: true

      volumes:
        - name: html-content
          emptyDir: {}
        - name: repo-temp
          emptyDir: {}
        - name: customize-script
          configMap:
            name: customize-script
            defaultMode: 0755

---
apiVersion: v1
kind: Service
metadata:
  name: custom-site-svc
spec:
  selector:
    app: custom-site
  ports:
    - port: 80
      targetPort: 80

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: custom-site-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: custom-site-svc
                port:
                  number: 80


kubectl apply -f static-site-custom.yaml


kubectl get pods -w
kubectl describe pod custom-static-site-7bbdf99ffb-kd2zq

# Get pod IP to compare to output on website
kubectl get pods -o wide
kubectl get all  # Shows pods, deployment, replicaset, service
kubectl get ingress  # Shows your Ingress and its ADDRESS (should be the MetalLB IP like 192.168.11.200)

# Get the IP used to access the site (from Ingress or Service):
# Test from any machine on your LAN: 192.168.11.200.  Note Use "New Private Window" in browser for best results to see pod info change on refresh.
kubectl get svc -n ingress-nginx


# Scale up to test multiple pods and load balancing:
kubectl scale deployment custom-static-site --replicas=9
# Watch Pods come up and see how they get distributed across nodes (if you have more than one worker):
kubectl get pods -w
kubectl get pods -o wide
# Test from any machine on your LAN: 192.168.11.200.  Note Use "New Private Window" in browser for best results to see pod info change on refresh.

# Troubleshooting: Destory Deployment and Pods to force re-creation and re-cloning if you make changes to the GitHub repo and want to test them quickly without waiting for a rollout restart:
kubectl delete pod -l app=custom-site --force --grace-period=0
kubectl delete deployment custom-static-site --ignore-not-found
