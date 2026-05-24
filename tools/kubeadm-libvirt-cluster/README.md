# kubeadm-libvirt-cluster

A lightweight infrastructure project for provisioning a reproducible multi-node Kubernetes environment with kubeadm for local development and infrastructure experimentation using:

- Terraform
- libvirt / QEMU
- cloud-init
- Ansible

The project also deploys a minimal monitoring stack (Prometheus, node-exporter, Grafana) to validate cluster health and observability.

---

## Requirements

- Terraform
- Ansible
- libvirt / QEMU
- jq
- SSH keypair

---

## Cloud Images

Supported cloud images:

- Debian: https://cloud.debian.org/images/cloud/
- Ubuntu: https://cloud-images.ubuntu.com/

### Default Image

This project currently uses the Debian 13 (Trixie) generic cloud image:

```bash
wget -P terraform/images \
https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2
```

## Architecture Flow
The following diagram illustrates the full provisioning and cluster bootstrap workflow:
```text
terraform/
(infrastructure definitions)
        │
        ▼
Terraform Provisioning
┌───────────────────────────┐
│ create network            │
│ create master/worker VMs  │
│ attach cloud-init config  │
└───────────────┬───────────┘
                │
                ▼
        libvirt / QEMU
     ┌──────────┼───────────┐
     ▼          ▼           ▼
   VM boot    networking    IP allocation
                │
                ▼
           cloud-init
┌───────────────────────────┐
│ configure users           │
│ inject SSH keys           │
│ bootstrap VM instance     │
└───────────────┬───────────┘
                │
                ▼
generate_ansible_inventory.sh
        │
        ▼
Ansible Inventory (hosts.ini)
        │
        ▼
    Ansible Cluster Setup
    ansible-playbook playbooks/cluster.yml
┌───────────────────────────┐
│ common role               │
│ - install requirements    │
│ - configure containerd    │
│ - configure Kubernetes    │
│                           │
│ master role               │
│ - initialize master node  │
│ - deploy CNI              │
│ - generate join command   │
│                           │
│ worker role               │
│ - join worker nodes       │
└───────────────┬───────────┘
                │
                ▼
      Kubernetes Cluster
┌───────────────────────────┐
│ control-plane active      │
│ workers connected         │
│ cluster networking ready  │
└───────────────┬───────────┘
                │
                ▼
ansible-playbook playbooks/monitoring_deployment.yml
┌───────────────────────────┐
│ copy manifests            │
│ render manifests          │
│ deploy manifests          │
└───────────────┬───────────┘
     ┌──────────┼───────────┐
     ▼          ▼           ▼
 Prometheus    Grafana    node-exporter
                │
                ▼
      Observable Cluster
```

---

## Configuration

Cluster sizing, networking, and VM settings can be customized in:

```text
terraform/terraform.tfvars
```

Example configuration:

```hcl
master = {
  memory    = 4096
  vcpu      = 4
  disk_size = 20 * 1024 * 1024 * 1024

  host = 50
}

worker = {
  count = 3

  memory    = 2048
  vcpu      = 2
  disk_size = 20 * 1024 * 1024 * 1024

  start_host = 51
}

network = {
  subnet  = "192.168.122.0"
  gateway = "192.168.122.1"
  cidr    = 24

  dns = ["1.1.1.1", "8.8.8.8"]
}

base_image = "debian-13-genericcloud-amd64.qcow2"

ssh_user = "debian-vm-user"

ssh_public_key_path = "~/.ssh/id_ed25519.pub"
```

---

## Provision Infrastructure

Initialize and create the virtual machines:

```bash
cd terraform

terraform init
terraform apply
```

---

## Generate Ansible Inventory

After Terraform provisioning completes:

```bash
./generate_ansible_inventory.sh
```

---

## Configure Kubernetes Cluster

Run the Ansible playbook to bootstrap Kubernetes:

```bash
cd ../ansible

ansible-playbook playbooks/cluster.yml
```

---

## Deploy Monitoring Stack

Deploy Prometheus, Grafana, and node-exporter:

```bash
ansible-playbook playbooks/monitoring_deployment.yml
```

---

## Verify Cluster Status

```bash
kubectl get nodes
```

Expected output:

```text
NAME                 STATUS   ROLES           VERSION
debian-vm-master     Ready    control-plane   v1.34.x
debian-vm-worker-1   Ready    <none>          v1.34.x
debian-vm-worker-2   Ready    <none>          v1.34.x
debian-vm-worker-3   Ready    <none>          v1.34.x
```


## Access Services

## Grafana

```text
http://<master-node-ip>:30300
```

## Prometheus

```text
http://<master-node-ip>:30090
```

---

## Rebuild the Cluster

Destroy and recreate the entire environment:

```bash
cd terraform

terraform destroy
terraform apply

./generate_ansible_inventory.sh

cd ../ansible

ansible-playbook playbooks/cluster.yml
ansible-playbook playbooks/monitoring_deployment.yml
```

---
