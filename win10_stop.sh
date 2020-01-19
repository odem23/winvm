#/bin/bash

VMNAME="win10"

# Check if started

#for p in $(ps aux | grep qemu-system-x86_64 | grep $VMNAME | grep -v sudo | grep -v grep | awk -F' ' '{print $2}')
for p in $( sudo ps aux | grep $VMNAME | grep qemu-system-x86_64 | grep -v sudo | grep -v grep | awk -F' ' '{print $2}' )
do
	#sudo kill $p
	#ps aux | grep $p
#	ps aux | grep $p
	sudo kill -9 $p
	#echo $p

done


