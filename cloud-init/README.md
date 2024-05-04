1. Download the ISO using the GUI https://cloud-images.ubuntu.com or


2. Create the VM via CLI
```
qm create 5001 --name "debian-bookworm-cloudinit" \
  --ostype l26 \
  --memory 4096 \
  --cpu host --socket 1 --core 2 \
  --bios ovmf \
  --machine q35 \
  --efidisk0 init:0,pre-enrolled-keys=0 \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci

qm set 5001 \
  --scsi0 init:0,ssd=on,import-from=/mnt/pve/iso/template/iso/debian-12-generic-amd64.qcow2
qm set 5001 --ide2 init:cloudinit
qm set 5001 --boot order=scsi0
qm set 5001 --vga serial0 --serial0 socket \

qm set 5001 --ipconfig0 ip=dhcp
qm set 5001 --ciuser administrator
qm set 5001 --cipassword password123
qm set 5001 --sshkeys ~/.ssh/id_rsa.pub


```
3. Create the Cloud-Init template
```
qm template 5001
```
4. Deploy new VMs by cloning the template (full clone)

```
qm clone 5001 231 \
  --name k3s-node01 \
  --full true \
  --target james \
  --storage tank

qm set 231 --ipconfig0 ip=10.10.101.231/23,gw=10.10.100.1
qm disk resize 231 scsi0 +5G
```

qm clone 5002 231 \
  --name k3s-node01 \
  --full true \
  --target james \
  --storage tank

qm set 231 --ipconfig0 ip=10.10.101.231/23,gw=10.10.100.1
qm disk resize 231 scsi0 +5G