if [[ $# -eq 1 ]]
then
wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloud>
qm create $1 --memory 2048 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
qm disk import $1 ubuntu-22.04-server-cloudimg-amd64.img local-lvm
qm set $1 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$1-disk-0
qm set $1 --ide2 local-lvm:cloudinit
qm set $1 --boot c --bootdisk scsi0
qm set $1 --serial0 socket --vga serial0

else
echo "please provide a [VM ID#]"
fi