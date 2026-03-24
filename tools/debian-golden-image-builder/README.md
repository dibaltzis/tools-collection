# debian-golden-image-builder

Scripts to create a Debian golden VM and disposable clones using **libvirt** and **cloud-init**.

---

### Files

```
.
├── create-golden-image.sh
├── create-clone.sh
├── debian-13-genericcloud-amd64.qcow2
└── id_ed25519.pub
```

---

### Setup

1. Download Debian cloud image:
   https://cloud.debian.org/images/cloud/

2. Place the `.qcow2` file in this directory

3. Add your SSH public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub > id_ed25519.pub
   ```

4. Edit `create-golden-image.sh`:
   - `VM_NAME`
   - `VM_USER`

5. Make scripts executable:
   ```bash
   chmod +x create-golden-image.sh create-clone.sh
   ```

---

### Create golden VM (one-time)

```bash
sudo ./create-golden-image.sh
```

Then shut it down:

```bash
sudo virsh shutdown <VM_NAME>
```

---

### Create clones

```bash
sudo ./create-clone.sh debian-amd64-dev-01
sudo ./create-clone.sh debian-amd64-dev-02
```

---

### Rules

- Do not modify the golden VM
- Always shut it down before cloning
- Work only on clones