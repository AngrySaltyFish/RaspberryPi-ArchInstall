#!/bin/bash
StartDir=$(dirname "$(readlink -fn "$0")")
cd "${StartDir}"
printf "***Raspberry Pi ArchInstall***\n"

function ConfirmValidation {
  printf "The ArchARM image downloaded can be confirmed against its signiture\n"
  read -p "Do you want to run this check (Y is strongly recomended) (Y/N): " ValidationChoice
  case ${ValidationChoice} in
    [y]|[Y]) ImageValidation=true;;
    [n]|[N]) ImageValidation=false;;
    *) printf "Invaild Selction\n"; ConfirmValidation;;
  esac
}
ConfirmValidation

function SelectDevice {
  printf "\nDevices found:\n"
  lsblk
  printf "\n"
  read -p "Enter device name to install to: " ArchPiDevice
  ArchPiDevice="/dev/${ArchPiDevice}"
  if [ ${ArchPiDevice} != "/dev/" ]; then #Deny just an empty string for just /dev
    if [[ -e ${ArchPiDevice} ]]; then #Check if device exists in /dev/
      ConfirmDriveChoice
    else
      printf ""
    fi
  else
    printf "\nInvaild device choice!"""""
    SelectDevice
  fi
}

function ConfirmDriveChoice {
  printf "\nInstalling will erase all data on ${ArchPiDevice}\n"
  read -p "Are you sure you want to continue? (Y/N): " ConfirmChoice
  case ${ConfirmChoice} in
    [y]|[Y]) ;; #WillContineWithScript
    [n]|[N]) SelectDevice ;;
    *) printf "Invaild selection";ConfirmDriveChoice;;
  esac
}
SelectDevice

printf "[1/6] Getting read to install to ${ArchPiDevice}\n"
umount ${ArchPiDevice}* &>/dev/null
rm -r .ArchPiSDTemp &>/dev/null  #Remove temp folder from any unfinished run
mkdir .ArchPiSDTemp
cd .ArchPiSDTemp

printf "[2/6] Setting up device paritions\n"
##SetupPartitons##
echo "o
n
p
1

+100M
t
c
n
p
2


w
" | fdisk -W always ${ArchPiDevice} &>/dev/null
partprobe ${ArchPiDevice} #Make the kernal use the new partition structure !

printf "[3/6] Creating new file system and mounting it\n"
##File system + Mounting##
mkfs.vfat ${ArchPiDevice}p1 &>/dev/null
mkdir ArchPiSDBoot
mount ${ArchPiDevice}p1 ArchPiSDBoot &>/dev/null

mkfs.ext4 ${ArchPiDevice}p2 &>/dev/null
mkdir ArchPiSDRoot
mount ${ArchPiDevice}p2 ArchPiSDRoot &>/dev/null

printf "[4/6] Downloading lastest image (This might take a while...)   "
function ValidateDownload {
  printf "Validating download...."
  wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz.sig -O ArchLinuxARM-rpi-latest.tar.gz.sig &>/dev/null
  gpg --keyserver-options auto-key-retrieve --verify ArchLinuxARM-rpi-latest.tar.gz.sig &>/dev/null
  if [ $? -eq 0 ]; then
    printf "Success\n"
  else
    printf "Failed!!! \nExiting now...\n"
    exit
  fi
}
wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz -O ArchLinuxARM-rpi-latest.tar.gz &>/dev/null
if [ "$ImageValidation" = true ]; then
  ValidateDownload
else
  printf "....Validation skipped :(\n"
fi


printf "[5/6] Installing image to ${ArchPiDevice} (This will also take a while!)\n"
bsdtar -xpf ArchLinuxARM-rpi-latest.tar.gz -C ArchPiSDRoot &>/dev/null
mv ArchPiSDRoot/boot/* ArchPiSDBoot
sync

printf "[6/6] Finishing up\n"
umount ArchPiSDBoot ArchPiSDRoot
cd "${StartDir}"
rm -r .ArchPiSDTemp

printf "\nInstall complete \nDefault usernames/password: alarm/alarm + root/root\n"
notify-send "Raspberry Pi ArchInstall" "Installtion to ${ArchPiDevice} is complete!"
