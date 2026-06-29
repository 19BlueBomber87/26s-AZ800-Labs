# Storage - AZ-800 Labs

This section covers core **Storage** concepts for the Windows Server Hybrid Administrator (AZ-800) certification. It includes file systems, sectors/allocation units, Storage Spaces, Storage Spaces Direct (S2D), SMB 3.0, Failover Clustering, and hybrid file server solutions with Azure Files.

Perfect for hands-on lab work, exam prep, and real-world enterprise storage design.

## What is a File System?

A file system is the method and data structure that an operating system uses to control how data is stored and retrieved on a storage device. It defines the rules for organizing files in a hierarchical structure, managing file names, formats, permissions, and metadata.

All Windows file systems are built around three core storage components:
- **Files** — A logical unit that contains related data.
- **Directories (Folders)** — Containers used to organize files and other directories.
- **Volumes** — Logical partitions that hold directories and files.

![Windows File System Types](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/01-WhatIsAFileSystem.jpg)

### Windows File System Types

#### FAT, FAT32, and exFAT
Oldest and simplest. Not suitable for production servers (no file-level security). Best for removable media.

#### NTFS (NT File System)
The standard for Windows Server. Required for AD DS and most server roles.

**Key Features:**
- ACLs, auditing, granular permissions
- Journaling for crash recovery
- Compression and EFS (mutually exclusive)
- Disk quotas, hard links, symbolic links

#### ReFS (Resilient File System)
Microsoft’s modern file system for high reliability and large-scale storage.

**Strengths:**
- Excellent data integrity and online repair
- Massive volume/file support (up to 35 PB+)
- Block-level deduplication
- Optimized for virtualized workloads

**Recommended** for data volumes in Windows Server 2025.

![What is A File System](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/02-WindowsFileSystemTypes.jpg)

## Sectors and Allocation Units

![Sector Allocation units](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/03-SectorAllocationUnits.jpg)

**Sector** = Smallest physical unit the disk can read/write (usually 4 KB on modern drives).

**Cluster (Allocation Unit)** = Smallest amount of disk space a file system can allocate to a file.

![Physical vs. Logical Sector Size](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/04-Physical%20vs.%20Logical%20SectorSize.jpg)

**Best Practice:** Match cluster size to your workload and ensure alignment with physical sectors.

## Storage Spaces (Normal / Traditional)

![Storage Spaces Overview](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/05-StorageSpaces.jpg)

Storage Spaces is Microsoft’s software-defined storage feature (introduced in Windows Server 2012). It pools physical disks and creates resilient virtual disks.

**Key Features:**
- Storage Pools (groups of disks)
- Virtual Disks with resiliency: Simple, Mirror (2/3-way), Parity (single/dual)
- Thin provisioning and tiering (SSD + HDD)
- Single-server only

**Limitations:** No automatic failover across servers.

**Regular Storage Spaces does NOT require SMB 3.0** — storage is local to one server.


## Horizontal Scaling vs Vertical Scaling

Horizontal scaling is often considered more cost-effective because you can grow incrementally using commodity hardware, while vertical scaling usually requires increasingly expensive high-end hardware.

### Why Horizontal Scaling Can Be More Cost-Effective

* Scale gradually: Add servers only when needed.
* Use cheaper hardware: Several standard servers are often less expensive than one high-performance enterprise server.
* Avoid large upfront investments: Buy one additional server instead of replacing an entire server.
* Better availability: If one server fails, others continue serving users.
* Lower upgrade risk: Adding a node is typically easier than migrating to a larger server.
* Cloud-friendly: Easily add or remove instances in Azure, AWS, etc.

![Vertical Scaling vs Horizontal Scaling](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/05.1-Vertical%20scaling%20vs.Horizontal%20scaling.jpg)



## SMB (Server Message Block)

![SMB](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/06-SMB.jpg)

SMB is the standard Windows file-sharing protocol.

**SMB 3.0+ Key Enhancements:**
- **SMB Direct (RDMA)** — Low-latency, low-CPU data transfers
- **SMB Multichannel** — Uses multiple NICs for bandwidth + redundancy

## Storage Spaces Direct (S2D)

![S2D](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/07-S2D.jpg)

S2D is Microsoft’s hyper-converged software-defined storage (Windows Server 2016+). It pools local disks across multiple cluster nodes.

**Requires:**
- Windows Failover Clustering
- SMB 3.0+ (Software Storage Bus)
- Recommended: 10 GbE+ with RDMA

**Benefits:** High availability, scalability (2–16 nodes), tiering, deduplication, etc.

## Failover Clustering

![Fail Over Cluster ADDS](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/08-FailOverCluster-%20ADDS.jpg)

Failover Clustering provides high availability by allowing multiple servers (nodes) to act as one system. Essential for S2D.

**Core Components:**
- Cluster Nodes (same AD domain)
- Cluster Shared Volumes (CSV)
- Networks (Management, Heartbeat, Live Migration)
- Quorum (Disk, File Share, Cloud Witness)

## Hybrid File Server Infrastructure with Azure Files

![Hybrid File Server Infrastructure](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/09-Hybrid%20File%20Server%20Infrastructure.jpg)

**Azure Files** — Fully managed, serverless file shares in Azure (SMB, NFS, REST).

**Azure File Sync** — Syncs Azure Files with on-premises servers for hybrid scenarios:
- Cloud tiering
- Multi-site sync
- Cloud backup & snapshots
- Disaster recovery

## Azure Arc + RBAC

**Azure Arc** extends Azure’s security, governance, and cloud-native services to your hybrid, multicloud, and edge environments — including Windows/Linux servers, Kubernetes clusters, SQL Servers, and more.

Once onboarded, Arc-enabled resources become native Azure Resource Manager (ARM) resources, giving you **full Azure RBAC support**.

![RBAC Basics](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/10-RBAC-BasicDiagram.jpg)

![Azure Arc Overview](https://raw.githubusercontent.com/19BlueBomber87/26s-AZ800-Labs/refs/heads/main/Storage-S2D-AzureFileSyncWithAzArc-StorageSpaces-Volumes/VisualizationDiagrams/11-AzArc.jpg)

### Key Capabilities
- Azure Policy (guest configuration)
- Microsoft Defender for Cloud
- Microsoft Sentinel
- Azure Monitor
- Azure RBAC at any scope

**Example:** Grant the Operations team *Contributor* access on an Arc Resource Group, while Auditors get *Reader* access.

## Lab Recommendations
- Build Storage Spaces labs (single server)
- Deploy a 2-node S2D cluster with Failover Clustering
- Configure Azure File Sync for hybrid scenarios
- Practice NTFS vs ReFS formatting and performance testing

---

**Repo:** [26s-AZ800-Labs](https://github.com/19BlueBomber87/26s-AZ800-Labs)  
**YouTube Series:** Search for "26s AZ-800 Labs" on YouTube for video walkthroughs.
## YouTube Playlist

Full video series: [26s-AZ-800 Labs Playlist](https://www.youtube.com/playlist?list=PLNCpp1kkXtdLMO55tSqb15Ra-CC6wAAcC)
