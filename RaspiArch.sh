#!/bin/bash
BINDER=$(dirname "$(readlink -fn "$0")") #Why is this variable in caps when all other variables are in capital camels, aren't all variables in bash global?
cd "$BINDER"
echo "***Raspberry Pi ArchInstall***"

function SelectDevice {
  echo "" #You should use "printf" instead of echo as it is more reliable and has support for special chars like "\n"
  echo "Devices found:"
  lsblk
  echo ""
  read -p "Enter device name to install to: " ArchPiDevice
  ArchPiDevice="/dev/${ArchPiDevice}"
  if [[ -e ${ArchPiDevice} ]]; then
    ConfirmDriveChoice
  else
    echo "Invaild device choice!"
    SelectDevice
  fi
}

function ConfirmDriveChoice {
  echo ""
  echo "Installing will erase all data on ${ArchPiDevice}"
  read -p "Are you sure you want to continue? (Y/N): " ConfirmChoice
  # What about lower case?
  case ${ConfirmChoice} in
    [y]|[Y]) ;;
    [n]|[N]) SelectDevice ;;
    *) echo "Invaild selection"; ConfirmDriveChoice;; #Am i right in thinking this is the default action if not you should implement one
  esac
}
SelectDevice

# It might be worth piping the stdout and stderr to log files

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

echo "[4/6] Downloading lastest image (This might take a while...)" #perhaps you should create a process on the side using "&" to download this to improve performence
##Install ArchArm##
wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz -O  ArchLinuxArm-rpi-latest.tar.gz &>/dev/null #You should sign this with md5 to validate
echo "[5/6] Installing image to ${ArchPiDevice} (This will also take a while!)"
bsdtar -xpf ArchLinuxArm-rpi-latest.tar.gz -C ArchPiSDRoot >/dev/null
sync
mv ArchPiSDRoot/boot/* ArchPiSDBoot

echo "[6/6] Finishing up"
##Finishing UP##
sync #The sync command is repeated twice, is this really necessary?
umount ArchPiSDBoot
umount ArchPiSDRoot
cd "$BINDER"
rm -r .ArchPiSDTemp

echo "Install complete "
echo "Default usernames/password: alarm/alarm + root/root"
notify-send "Raspberry Pi ArchInstall" "Installtion to ${ArchPiDevice} is complete!"
