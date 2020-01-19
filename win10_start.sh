#!/bin/bash

#
# Script to start and maintain a qemu-based Windows guest
# Applies several turing parameters and configurations
# Use variables in config section to customize the target
#

# Config #############################
VMNAME="win10"
HOMEDIR_PA_USER="/home/odem"
HOMEDIR_QEMU_USER="/root"
THREAD_LIST="0,1,2,3"
PROG="qemu-system-x86_64"
PIDFILE="/home/odem/.win10.pid"
SND_FILE_SUCCESS="/usr/share/sounds/freedesktop/stereo/service-login.oga"
SND_FILE_ERROR="/usr/share/sounds/freedesktop/stereo/service-logout.oga"
SND_SINK="alsa_output.pci-0000_00_1b.0.analog-stereo" # found with: 'pacmd list-sinks'
SND_VOLUME="30000" # Range: 0 - 65536
# Config End ##########################



# Check if already started
HASPID=`sudo ps aux | grep $VMNAME | grep qemu-system-x86_64 | grep -v sudo | grep -v grep `
if [ "$HASPID" != "" ] ; then
	echo "Already started"
    paplay --device=$SND_SINK --volume=$SND_VOLUME $SND_FILE_ERROR
	exit 1
fi


# Prepare vfio
VGA_ADR_0="0000:01:00.0"
VGA_ADR_1="0000:01:00.1"
VGA_ADR_2="0000:01:00.2"
VGA_ADR_3="0000:01:00.3"
VGA_ID_0="10de 1e84"
VGA_ID_1="10de 10f8"
VGA_ID_2="10de 1ad8"
VGA_ID_3="10de 1ad9"
sudo sh -c "echo '$VGA_ID_0' > /sys/bus/pci/drivers/vfio-pci/new_id"
sudo sh -c "echo '$VGA_ADR_0' > /sys/bus/pci/devices/$VGA_ADR_0/driver/unbind"
sudo sh -c "echo '$VGA_ADR_0' > /sys/bus/pci/drivers/vfio-pci/bind"
sudo sh -c "echo '$VGA_ID_1' > /sys/bus/pci/drivers/vfio-pci/new_id"
sudo sh -c "echo '$VGA_ADR_1' > /sys/bus/pci/devices/$VGA_ADR_1/driver/unbind"
sudo sh -c "echo '$VGA_ADR_1' > /sys/bus/pci/drivers/vfio-pci/bind"
sudo sh -c "echo '$VGA_ID_2' > /sys/bus/pci/drivers/vfio-pci/new_id"
sudo sh -c "echo '$VGA_ADR_2' > /sys/bus/pci/devices/$VGA_ADR_2/driver/unbind"
sudo sh -c "echo '$VGA_ADR_2' > /sys/bus/pci/drivers/vfio-pci/bind"
sudo sh -c "echo '$VGA_ID_3' > /sys/bus/pci/drivers/vfio-pci/new_id"
sudo sh -c "echo '$VGA_ADR_3' > /sys/bus/pci/devices/$VGA_ADR_3/driver/unbind"
sudo sh -c "echo '$VGA_ADR_3' > /sys/bus/pci/drivers/vfio-pci/bind"

# Hugepages 
sudo sysctl vm.nr_hugepages=15 # 6000 * 2048 == 12288000 (12gb)

# prepare pulseaudio server
export QEMU_AUDIO_DRV=pa
export QEMU_PA_SAMPLES=8192
export QEMU_AUDIO_TIMER_PERIOD=99
export QEMU_PA_SERVER=/run/user/1000/pulse/native
sudo cp $HOMEDIR_PA_USER/.config/pulse/cookie $HOMEDIR_QEMU_USER/.config/pulse/cookie

# Main
NAME="-name $VMNAME,process=$VMNAME,debug-threads=on"
ARCH="-M q35,accel=kvm,kernel_irqchip=on -enable-kvm "
CPU="-smp 4,sockets=2,cores=2,threads=1"
CPU="$CPU -cpu host,+ssse3,+sse4.1,+sse4.2,+x2apic,kvm=off,vme=on,ss=on,f16c=on,rdrand=on,hypervisor=on,arat=on,tsc_adjust=on,umip=on,xsaveopt=on,pdpe1gb=on,abm=on,hv_relaxed,hv_vapic,hv_time,hv_crash,hv_reset,hv_vpindex,hv_runtime,hv_synic,hv_stimer,hv_vendor_id=whatever,hv_spinlocks=0x1fff"
RTC="-realtime mlock=off -rtc base=localtime,driftfix=slew"
OPTIONALS="-msg timestamp=on"
MEM=" -m 11G -mem-prealloc -mem-path /dev/hugepages"
DISABLED="-serial none -parallel none"
MONITORMODE="-monitor telnet:127.0.0.1:55555,server,nowait"
BUSSES="-device ich9-ahci,id=ahci"
BUSSES="$BUSSES -device virtio-scsi-pci,id=scsi0"
BUSSES="$BUSSES -device virtio-scsi-pci,id=scsi1"
BUSSES="$BUSSES -device ioh3420,bus=pcie.0,addr=1c.0,multifunction=on,port=1,chassis=1,id=root.1"
BUSSES="$BUSSES -device virtio-net-pci,netdev=ionet0"

HEAD="$NAME $ARCH $CPU $RTC $OPTIONALS $MEM $DISABLED $MONITORMODE $BUSSES"

# Storage
OSFILE="/dev/sdc"
DATAFILE="/dev/sdb"
DATAFILE2="/home/odem/repo/github/winguest/foo.img"
VIOFILE="/media/devstore/vm/winvm/virtio-win-0.1.173.iso"
BOOTCDFILE="/media/devstore/vm/winvm/Win10_1909_German_x64.iso"
EFIFILE_CODE="/usr/share/OVMF/OVMF_CODE.fd"
EFIFILE_VARS="/usr/share/OVMF/OVMF_VARS.fd"
DISKPARAMS="cache=none,discard=unmap,aio=threads"
EFI_CODE="-drive file=$EFIFILE_CODE,if=pflash,format=raw,unit=0,readonly=on"
EFI_VARS="-drive file=/tmp/my_vars.fd,if=pflash,format=raw,unit=1"
CDBOOT="-drive file=$BOOTCDFILE,format=raw,if=none,id=bootcd,$DISKPARAMS -device ide-cd,bus=ahci.0,drive=bootcd"
CDVIRT="-drive file=$VIOFILE,format=raw,if=none,id=virtiocd,$DISKPARAMS -device ide-cd,bus=ahci.1,drive=virtiocd"
OSDISK="-drive file=$OSFILE,format=raw,if=none,id=osdisk,$DISKPARAMS  -device virtio-blk-pci,drive=osdisk"
DATADISK="-drive file=$DATAFILE,format=raw,if=none,id=datadisk,$DISKPARAMS -device virtio-blk-pci,drive=datadisk"
DATADISK2="-drive file=$DATAFILE2,format=raw,if=none,id=datadisk2,$DISKPARAMS -device virtio-blk-pci,drive=datadisk2"
STORAGE="$EFI_CODE $CDBOOT $CDVIRT $OSDISK $DATADISK $DATADISK2"
rm /tmp/my_vars.fd
cp $EFIFILE_VARS /tmp/my_vars.fd

# Components
AUDIO="-soundhw hda"
NETWORK="-netdev tap,id=ionet0,ifname=vmtap0,script=no,downscript=no"
USBDEVS="-usb -device usb-host,vendorid=0x1532,productid=0x0067" 			# Mouse
USBDEVS="$USBDEVS -usb -device usb-host,vendorid=0x046d,productid=0x0a4d" 	# Headset
USBDEVS="$USBDEVS -device usb-host,vendorid=0x1532,productid=0x011a" 		# keyboard

# VGA
VGADEV="-device vfio-pci,host=01:00.0,bus=root.1,addr=00.0,multifunction=on"
VGADEV="$VGADEV -device vfio-pci,host=01:00.1,bus=root.1,addr=00.1"
VGADEV="$VGADEV -device vfio-pci,host=01:00.2,bus=root.1,addr=00.2"
VGADEV="$VGADEV -device vfio-pci,host=01:00.3,bus=root.1,addr=00.3"
VGADEV="$VGADEV -vga none -nographic"

COMPONENTS="$STORAGE $AUDIO $NETWORK $USBDEVS $VGADEV"

# Invoke
CMD="sudo $PROG $HEAD $COMPONENTS"
taskset -c $THREAD_LIST $CMD &

# Check result
sleep 5
PIDOF=`pidof $PROG`
if [[ "$PIDOF" == "" ]] ; then
	echo "VM was not created!"	
	paplay --device=$SND_SINK --volume=$SND_VOLUME $SND_FILE_ERROR
	exit 1
else
	paplay --device=$SND_SINK --volume=$SND_VOLUME $SND_FILE_SUCCESS
fi
echo "$PIDOF" > $PIDFILE

# Networking
sudo sh -c 'sleep 3 ; /etc/init.d/networking restart'

# Set cpu affinity host
sleep 15
cset shield -c 0,1,2,3
cset shield --kthread on
cset shield --shield --threads --pid $PIDOF

# Set cpu affinity guest
HOST_THREAD=0
for PID in $(pstree -pa $PIDOF | grep $VMNAME | awk -F',' '{print $2}' | awk '{print $1}' )  
do
    let HOST_THREAD+=1
	INDEX=$(($HOST_THREAD%4))
	FIELD=$(($INDEX+1))
    taskset -pc $(echo $THREAD_LIST | cut -d',' -f$FIELD) $PID
done

# Scheduling => chrt -f for FIFO-Scheduler
for p in $(pstree -pa $(pidof $PROG ) | grep $VMNAME | cut -d','  -f2 | cut -d' ' -f1)  
do
	sudo chrt -v -d -p 99 $p
done

# allow rt threads max cpu usage
sysctl kernel.sched_rt_runtime_us=-1
sysctl kernel.sched_rt_runtime_us=990000

# Watchdog => Cleans up system after vm closed
while :
do
	PIDOF=`pidof $PROG`
	echo "Looping..."
	if [[ "$PIDOF" == "" ]] ; then
		echo "VM was closed! Cleaning up..."
			
		cset shield --reset
		rm -rf $PIDFILE	

		# Reset usb devices
		for i in /sys/bus/pci/drivers/[uoex]hci_hcd/*:*; do
		  [ -e "$i" ] || continue
		  echo "${i##*/}" > "${i%/*}/unbind"
		  echo "${i##*/}" > "${i%/*}/bind"
		done

		paplay --device=$SND_SINK --volume=$SND_VOLUME $SND_FILE_ERROR
		break
	fi
	sleep 3
done


