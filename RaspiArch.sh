#!/bin/sh
##MJF##
BINDER=$(dirname "$(readlink -fn "$0")")
cd "$BINDER"

echo "***Raspberry Pi ArchInstall***"
echo ""
echo "Devices found:"
lsblk
echo""
read -p "Enter device name to install to: " ArchPiDevice
ArchPiDevice="/dev/${ArchPiDevice}"

if [[ ${ArchPiDevice} == sd* ]]; then
  echo "Don't install it to a HDD dumb ass"
  exit
fi

echo "[1/6] Getting read to install to ${ArchPiDevice}"
umount ${ArchPiDevice}* &>/dev/null
rm -r .ArchPiSDTemp &>/dev/null
mkdir .ArchPiSDTemp
cd .ArchPiSDTemp

echo "[2/6] Setting up device paritions"
##SetupPartitons##

echo "o
p
n
p
1

+100M
Y
t
c
n
p
2


Y
w
" | fdisk ${ArchPiDevice} &>/dev/null


echo "[3/6] Creating new file system + mounting it"
##File system + Mounting##
mkfs.vfat ${ArchPiDevice}p1 &>/dev/null
mkdir ArchPiSDBoot
mount ${ArchPiDevice}p1 ArchPiSDBoot >/dev/null

mkfs.ext4 ${ArchPiDevice}p2 &>/dev/null
mkdir ArchPiSDRoot
mount ${ArchPiDevice}p2 ArchPiSDRoot >/dev/null

echo "[4/6] Downloading lastest image (This might take a while...)"
##Install ArchArm##
wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz -O  ArchLinuxArm-rpi-latest.tar.gz &>/dev/null
echo "[5/6] Installing image to ${ArchPiDevice} (This will also take a while!)"
bsdtar -xpf ArchLinuxArm-rpi-latest.tar.gz -C ArchPiSDRoot >/dev/null
sync
mv ArchPiSDRoot/boot/* ArchPiSDBoot

echo "[6/6] Finishing up"
##Finishing UP##
sync
umount ArchPiSDBoot
umount ArchPiSDRoot
cd "$BINDER"
rm -r .ArchPiSDTemp

echo "Install complete "
echo "Default usernames: alarm, root"
echo "Default passwords: alarm, root"
notify-send "Raspberry Pi ArchInstall" "Installtion to ${ArchPiDevice} is complete!"
