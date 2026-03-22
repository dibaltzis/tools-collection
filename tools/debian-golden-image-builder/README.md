# Debian Golden Image + Clone Scripts

Scripts to create an immutable Debian golden VM and disposable clone VMs using **libvirt** and **cloud-init**.

---

## Files

```
.
├── create-golden-image.sh
├── create-clone.sh
├── debian-13-genericcloud-amd64.qcow2
└── id_ed25519.pub
```

---

## Setup

1. Download the Debian cloud image:

   https://cloud.debian.org/images/cloud/

2. Place the downloaded `.qcow2` file in this directory.

3. Copy your SSH public key:

   ```
   cat ~/.ssh/id_ed25519.pub > id_ed25519.pub
   ```

4. Edit `create-golden-image.sh` and set the following variables:

   - `VM_NAME`
   - `VM_USER`

5. Make the scripts executable:

   ```
   chmod +x create-golden-image.sh create-clone.sh
   ```

---

## Create Golden VM (one time)

```
sudo ./create-golden-image.sh
```

After the VM is created, shut it down:

```
sudo virsh shutdown <VM_NAME>
```

---

## Create Clone VMs

Example:

```
sudo ./create-clone.sh debian-amd64-dev-01
sudo ./create-clone.sh debian-amd64-dev-02
```

---

## Rules

- Do **not** log into or modify the golden VM
- Always shut down the golden VM before cloning
- Perform all work on clone VMs only