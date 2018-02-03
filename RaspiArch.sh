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
ArchPiDevice="/dev/$ArchPiDevice"
ArchPiDevicep1=""$ArchPiDevice"p1"
ArchPiDevicep2=""$ArchPiDevice"p2"

if [[ $ArchPiDevice == sd* ]]; then
  echo "Don't install it to a HDD dumb ass"
  exit
fi

echo "[1/6] Getting read to install to $ArchPiDevice"
sudo umount $ArchPiDevice* &>/dev/null
sudo rm -r .ArchPiSDTemp &>/dev/null
sudo mkdir .ArchPiSDTemp
cd .ArchPiSDTemp

echo "[2/6] Setting up device paritions"
##SetupPartitons##
(
  echo o
  echo p
  echo n
  echo p
  echo 1
  echo " "
  echo +100M
  #echo Y
  echo t
  echo c
  echo n
  echo p
  echo 2
  echo ""
  echo ""
  #echo Y
  echo w
) | sudo fdisk $ArchPiDevice &>/dev/null

echo "[3/6] Creating new file system + mounting it"
##File system + Mounting##
sudo mkfs.vfat $ArchPiDevicep1 &>/dev/null
sudo mkdir ArchPiSDBoot
sudo mount $ArchPiDevicep1 ArchPiSDBoot >/dev/null

sudo mkfs.ext4 $ArchPiDevicep2 &>/dev/null
sudo mkdir ArchPiSDRoot
sudo mount $ArchPiDevicep2 ArchPiSDRoot >/dev/null

echo "[4/6] Downloading lastest image (This might take a while...)"
##Install ArchArm##
sudo wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz -O  ArchLinuxArm-rpi-latest.tar.gz &>/dev/null
echo "[5/6] Installing image to $ArchPiDevice (This will take a while!)"
sudo bsdtar -xpf ArchLinuxArm-rpi-latest.tar.gz -C ArchPiSDRoot >/dev/null
sudo sync
sudo mv ArchPiSDRoot/boot/* ArchPiSDBoot

echo "[6/6] Finishing up"
##Finishing UP##
sudo sync
sudo umount ArchPiSDBoot
sudo umount ArchPiSDRoot
cd "$BINDER"
sudo rm -r .ArchPiSDTemp

echo "Install complete "
echo "Default usernames: alarm, root"
echo "Default passwords: alarm, root"
notify-send "Raspberry Pi ArchInstall" "Installtion to $ArchPiDevice is complete!"
