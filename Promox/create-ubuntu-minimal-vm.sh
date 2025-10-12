#https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Promox/create-ubuntu-minimal-vm.sh

if [[ $# -gt 1 ]]
then
FILE="ubuntu-24.04-server-cloudimg-amd64.img"
if [ ! -f "$FILE" ]; then
    wget https://cloud-images.ubuntu.com/releases/24.04/release/$FILE
    echo "Image created: $FILE"
else
    echo "Image already exists: $FILE"
fi

if [[ $# -gt 2 ]]
then
DSK=$3
else
DSK="local-lvm"
fi

qm create $1 --memory 2048 --name $2 --net0 virtio,bridge=vmbr0
qm disk import $1 ubuntu-24.04-server-cloudimg-amd64.img $DSK
qm set $1 --scsihw virtio-scsi-pci --scsi0 $DSK:vm-$1-disk-0
qm set $1 --ide2 $DSK:cloudinit
qm set $1 --boot c --bootdisk scsi0
qm set $1 --serial0 socket --vga serial0
echo "Done"

else
echo "please provide a [VM ID#] [VM Name] *[Dest DISK NAME]/local-lvm"
fi
