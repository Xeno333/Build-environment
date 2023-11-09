clear

echo 'Cleaning ./OUT.'
rm -r ./OUT/BIN/*

if test -f ./OUT/IMG/Disk.vdi; then
	rm -r ./OUT/IMG/Disk.vdi
fi
if test -f ./OUT/IMG/Disk.vdi; then
	rm -r ./OUT/IMG/Img.img
fi

echo 'Making empty image.'
cp ./RAW/IMG_GPT.img ./OUT/IMG/Img.img

echo
echo 'Compiling source code.'
	cd ./SRC/Boot
	./build.sh ./../../OUT/BIN/
	cd ..
	cd ..
	cd ./SRC/kernel
	./kbuild.sh ./../../OUT/BIN/ ./../../OUT/BIN/kernel.bin
	cd ..
	cd ..
	
echo
	ksize=$(du -k "./OUT/BIN/kernel.bin" | cut -f1)
echo "Kernel size is: " $ksize "k"

echo
echo 'Finding avalible loop device:'
	AVAIL_DEV=$(sudo losetup -f)
echo 'Found device: ' $AVAIL_DEV ''

echo
echo 'Adding Bootloader.'
	#Stage1
	sudo losetup $AVAIL_DEV ./OUT/IMG/Img.img
	sudo dd if=./OUT/BIN/Boot1.bin of=$AVAIL_DEV bs=440 count=1 &> /dev/null #Copy bootloader but not Sig reserved or MBR.
	sudo losetup -d $AVAIL_DEV
	#Stage2
	sudo losetup -o 1048576 $AVAIL_DEV ./OUT/IMG/Img.img
	sudo dd if=./OUT/BIN/Boot2.bin of=$AVAIL_DEV bs=512 count=4 &> /dev/null
	sudo losetup -d $AVAIL_DEV

echo 'Adding kernel to disk image.'
	sudo losetup -o 2097152 $AVAIL_DEV ./OUT/IMG/Img.img
	sudo dd if=./OUT/BIN/kernel.bin of=$AVAIL_DEV bs=1024 count=2048 &> /dev/null
	sudo losetup -d $AVAIL_DEV
echo


if command -v VBoxManage &> /dev/null; then
	echo 'Making vdi.'
		VBoxManage convertfromraw --uuid 0b14f489-3dd7-4dda-b5d3-8bc605f4029c --format VDI ./OUT/IMG/Img.img ./OUT/IMG/Disk.vdi &> /dev/null
	echo
	echo 'Running.'
		sudo qemu-system-x86_64 -vga std -cpu max -m 32M -hda ./OUT/IMG/Disk.vdi #-serial stdio -smp 2
else
	echo 'Running.'
		sudo qemu-system-x86_64 -vga std -cpu max -m 32M -drive file=./OUT/IMG/Img.img,format=raw,index=0,media=disk #-serial stdio -smp 2
fi

echo
echo 'Done.'
exit
