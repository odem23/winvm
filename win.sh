#!/bin/bash


PROG="sudo qemu-system-x86_64"
NAME="-name $vmname,process=$vmname"
ARCH="-M q35,accel=kvm -enable-kvm"
CPU="-smp 4,sockets=1,cores=4,threads=1"
MEM=" -m 12G"
DISABLED="-serial none -parallel none"
HEAD="$PROG $NAME $ARCH $CPU $MEM $DISABLED"

OSFILE="/dev/sdc"
DATAFILE="/media/devstore/vm/winvm/win10.img"
VIOFILE="/media/devstore/vm/winvm/virtio-win-0.1.173.iso"
BOOTCDFILE="/media/devstore/vm/winvm/Win10_1909_German_x64.iso"
EFIFILE_CODE="/usr/share/OVMF/OVMF_CODE.fd"
EFIFILE_VARS="/usr/share/OVMF/OVMF_VARS.fd"

DISKPARAMS="cache=none,discard=unmap,detect-zeroes=unmap,aio=native"
BUSSES="-device ich9-ahci,id=ahci -device virtio-scsi-pci,id=scsi0 -device virtio-scsi-pci,id=scsi1"

CDBOOT="-drive file=$BOOTCDFILE,format=raw,if=none,id=bootcd,$DISKPARAMS -device ide-cd,bus=ahci.0,drive=bootcd"
CDBOOT="-drive file=/media/devstore/vm/winvm/Win10_1909_German_x64.iso,index=1,media=cdrom"
CDVIRT="-drive file=$VIOFILE,format=raw,if=none,id=virtiocd,$DISKPARAMS -device ide-cd,bus=ahci.1,drive=virtiocd"
OSDISK="-drive file=$OSFILE,format=raw,if=none,id=osdisk,$DISKPARAMS  -device ide-drive,bus=ahci.2,drive=osdisk"

OSDISK="-drive file=$OSFILE,format=raw,if=none,id=osdisk,$DISKPARAMS -device scsi-hd,bus=scsi0.0,drive=osdisk"
DATADISK="-drive file=$DATAFILE,format=raw,if=none,id=datadisk,$DISKPARAMS -device scsi-hd,bus=scsi1.0,drive=datadisk"

cp /usr/share/OVMF/OVMF_VARS.fd /tmp/my_vars.fd
EFI_CODE="-drive file=$EFIFILE_CODE,if=pflash,format=raw,unit=0,readonly=on"
EFI_VARS="-drive file=$EFIFILE_VARS,if=pflash,format=raw,unit=1"

STORAGE="$BUSSES $EFI_CODE $EFI_VARS $CDBOOT $CDVIRT $OSDISK"




CMD="$HEAD $STORAGE -boot order=d"

echo "HEAD   : '$HEAD'"
echo "STORAGE: '$STORAGE'"
echo "CMD    : '$CMD'"

$CMD


