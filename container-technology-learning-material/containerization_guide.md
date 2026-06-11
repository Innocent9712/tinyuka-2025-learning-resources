# An Introduction to Containerization

## What is Containerization?

Containerization is a lightweight and portable method of packaging an application and all its dependencies—such as libraries, configuration files, and binaries—into a single, isolated unit called a **container**. This container can then be run consistently on any infrastructure, whether it's a developer's laptop, a corporate data center, or the public cloud. The primary goal is to abstract the application from the underlying environment, ensuring that it works uniformly regardless of where it is deployed.

## How Containers Differ from Virtual Machines (VMs)

![Container vs. Virtual Machine](./img/container-vs-vm.jpeg)

While both containers and virtual machines provide isolated environments for running applications, they do so in fundamentally different ways. The key difference lies in how they interact with the host operating system (OS).

### Virtual Machines
A Virtual Machine runs a complete, independent guest OS on top of a hypervisor. This means each VM includes not just the application and its dependencies, but also an entire operating system, which can be resource-intensive.

### Containers
Containers, on the other hand, share the host system's OS kernel. They virtualize the operating system instead of the hardware. This makes them significantly more lightweight, faster to start, and less demanding on resources.

> **Key Insight:** The absence of a separate Guest OS for each container is what makes them so efficient.

## Core Linux Technologies: The Foundation of Containers

Modern containerization was built upon several fundamental technologies within the Linux kernel that provide the necessary isolation and resource management.

![Docker - Linux Core Components](./img/docker-linux-kernel-components.png)

### 1. Namespaces

Namespaces are a feature of the Linux kernel that partitions kernel resources such that one set of processes sees one set of resources while another set of processes sees a different set. This is the primary technology for creating the isolated environment of a container.

#### Key Namespace Types:

- **PID (Process ID):** Isolates the process ID number space, so processes inside a container can have their own PID 1 (init process)
- **NET (Network):** Provides each container with its own network stack, including network interfaces, IP addresses, and routing tables
- **MNT (Mount):** Allows each container to have its own filesystem hierarchy, preventing it from accessing files outside its designated directory structure
- **UTS (UNIX Timesharing System):** Isolates the hostname and domain name, allowing each container to have its own unique identity on the network
- **IPC (Inter-Process Communication):** Isolates resources for communication between processes, such as message queues
- **User:** Isolates user and group IDs, allowing a process to have a privileged root user inside the container without having those privileges on the host
- **Time:** Introduced in Linux kernel 5.6, the Time Namespace allows for the virtualization of system clocks, providing processes within a container with their own distinct view of the monotonic clock (CLOCK_MONOTONIC) and the boot time clock (CLOCK_BOOTTIME)

#### Time Namespace Use Case
The primary use case for the Time Namespace is for checkpointing and restoring containers. When a container is "frozen" or checkpointed, its processes are stopped. Upon restoration, which could happen much later on the same or a different host, there would be a significant jump in monotonic time. The Time Namespace allows the system to set an offset for these clocks inside the container, so from the application's perspective, time appears to flow continuously across the suspend/resume cycle.

### 2. Control Groups (cgroups)

While namespaces provide isolation, Control Groups (cgroups) are responsible for managing and limiting the system resources that a container can use. This is crucial for preventing a single container from consuming all available hardware resources and impacting other containers or the host system itself.

#### Resources Managed by cgroups:
- **CPU:** Allocate a specific amount of CPU time or set relative shares
- **Memory:** Limit the amount of memory a container can use
- **Disk I/O:** Control read/write speeds to storage devices
- **Network:** Limit network bandwidth

### 3. chroot

Although older and less comprehensive than namespaces, `chroot` (change root) was an important precursor to modern container isolation. It is a Unix system call that changes the root directory of the current process and its children. This means the process cannot "see" or access files outside of the new root directory, creating a basic form of filesystem isolation. While `chroot` laid the groundwork, modern containers rely on the more secure and extensive isolation provided by the MNT namespace.

## Docker: The Tool That Popularized Containers

While the underlying technologies like namespaces and cgroups existed in Linux for years, it was Docker that made containerization accessible and popular. Docker, Inc. created a toolset that simplified the process of building, sharing, and running containers.

### Common Docker Components

Docker consists of several key components that work together to provide a complete containerization platform:

![Docker Components](./img/docker-components.png)

- **Docker Client (`docker`):** The command-line interface (CLI) tool that you interact with. When you type a command like `docker run` or `docker build`, you're using the Docker client
- **Docker Daemon (`dockerd`):** The background service that runs on the host OS. It listens for API requests from the Docker Client and manages Docker objects such as images, containers, networks, and volumes
- **Docker Registry:** A system for storing and distributing Docker images. Docker Hub is the default public registry, but you can also run your own private registry

### The Docker Communication Flow

When you execute a command to run a container, a chain of communication is initiated. The architecture has become more modular over time to align with industry standards like the Open Container Initiative (OCI).

#### Simplified Flow:
1. **docker (Client) → dockerd (Daemon):** You issue a command like `docker run nginx`. The Docker client sends this command via a REST API to the dockerd daemon running on your machine
2. **dockerd → containerd:** The main Docker daemon no longer handles running containers directly. Instead, it makes a call to a high-level container runtime called containerd. dockerd primarily handles image management, networking, and volume management, while containerd manages the container lifecycle (start, stop, pause)
3. **containerd → runc:** containerd doesn't create the container itself. It calls a low-level OCI-compliant runtime, with runc being the default. containerd converts the desired Docker image into an OCI-compliant bundle
4. **runc → Container & Kernel:** runc is the component that finally creates the container. It interacts directly with the Linux kernel to create the namespaces and cgroups that form the isolated container environment. It then executes the command specified for the container (e.g., starting the nginx process)

This modular flow (`dockerd -> containerd -> runc`) allows different components to be swapped out, promoting a standardized container ecosystem.

## Container Runtimes

A container runtime is the software responsible for running containers. Following the creation of the Open Container Initiative (OCI), runtimes are now standardized.

### Types of Container Runtimes

#### Low-Level Runtimes
These are the basic runtimes that create and run containers. They are OCI-compliant. The most common example is **runc**, which is the default for both containerd and CRI-O.

#### High-Level Runtimes
These runtimes manage the full container lifecycle. They handle tasks like pulling images, managing container processes, and then using a low-level runtime to actually create the container.

**Examples:**
- **containerd:** The runtime used by Docker. It's a graduated CNCF (Cloud Native Computing Foundation) project
- **CRI-O:** An alternative high-level runtime created by Red Hat. It was specifically designed to be a lightweight runtime for Kubernetes

## Container Orchestration 🎵

Running one or two containers is easy. But what happens when you need to manage hundreds or thousands of containers across a fleet of servers in a production environment? This is where container orchestration comes in.

### What Does Orchestration Do?

Orchestration automates the deployment, management, scaling, and networking of containers. An orchestrator can:

- Schedule containers to run on different servers (nodes) based on available resources
- Handle service discovery, allowing containers to find and communicate with each other
- Automatically scale services up or down based on demand
- Perform health checks and restart failed containers
- Manage rolling updates to deploy new versions of an application with zero downtime

### Examples of Orchestrators

- **Docker Swarm:** Docker's native orchestration tool. Known for its simplicity and ease of use but is less feature-rich than Kubernetes
- **Kubernetes (K8s):** The industry-standard, open-source platform for container orchestration. Incredibly powerful and flexible, backed by the CNCF

## Kubernetes (K8s)

Kubernetes is the de facto standard for container orchestration. It provides a robust framework to run distributed systems resiliently.

### Kubernetes Architecture

A Kubernetes cluster is divided into two main parts: the **Control Plane** (which makes global decisions about the cluster) and the **Nodes** (the worker machines that run containers).

![Kubernetes Architecture](./img/components-of-kubernetes.svg)

#### Control Plane Components

- **kube-apiserver:** The frontend of the control plane. It exposes the Kubernetes API, which is how all other components and user commands interact with the cluster
- **etcd:** A consistent and highly-available key-value store used as Kubernetes' backing store for all cluster data (the "database" of the cluster)
- **kube-scheduler:** Watches for newly created Pods (the smallest deployable unit in Kubernetes, which can contain one or more containers) and selects a Node for them to run on
- **kube-controller-manager:** Runs controller processes that handle cluster-level functions, such as the Node Controller, Replication Controller, and Endpoint Controller

#### Node Components

- **kubelet:** An agent that runs on each node in the cluster. It ensures that containers described in PodSpecs are running and healthy
- **kube-proxy:** A network proxy that runs on each node, maintaining network rules and enabling communication for Pods from network sessions inside or outside of the cluster
- **Container Runtime:** The software used to run containers. This could be containerd, CRI-O, or any other Kubernetes CRI (Container Runtime Interface) compliant runtime

### Setting up a Kubernetes Cluster

There are several ways to get a Kubernetes cluster running:

1. **Local Machine:** For development and testing, using tools like Minikube, Kind, or Docker Desktop
2. **On-Premises:** Manually installing and configuring the control plane and nodes on your own servers using tools like kubeadm
3. **Cloud Provisioned (Managed Kubernetes):** The most common approach for production. A cloud provider manages the control plane for you, and you just manage the worker nodes

#### The Cloud Provisioned Approach

With managed Kubernetes, the cloud provider takes on the complex and critical task of ensuring the control plane (API server, etcd, etc.) is available, scalable, and secure. This lets you focus on deploying and managing your applications.

**Popular managed Kubernetes services include:**
- **Google Kubernetes Engine (GKE)** on Google Cloud Platform (GCP)
- **Amazon Elastic Kubernetes Service (EKS)** on Amazon Web Services (AWS)
- **Azure Kubernetes Service (AKS)** on Microsoft Azure

---

## Summary

Containerization represents a fundamental shift in how we package, deploy, and manage applications. Starting from core Linux technologies like namespaces and cgroups, evolving through Docker's user-friendly tooling, and culminating in sophisticated orchestration platforms like Kubernetes, containers have become the foundation of modern cloud-native applications.

The journey from understanding basic container isolation to managing complex distributed systems through Kubernetes orchestration provides developers and operations teams with powerful tools to build scalable, resilient, and portable applications.

Extra resources for further learning include:
- [Youtube Playlist on Linux Utilities that form the Core of Containerization Technology](https://youtube.com/playlist?list=PLdh-RwQzDsaNWBex2I09OFLCph7l_KnQE&si=dHJ8LAAEQnxQBOFV)
- [Docker Official Documentation](https://docs.docker.com/)
- [Kubernetes Official Documentation](https://kubernetes.io/docs/home/)
