#! /bin/bash

PROGNAME=$0
usage() {

  printf "

  This script starts a QEMU emulation of an attached Raspberry Pi SD card

  Usage: ${PROGNAME} [-d <Raspberry Pi's Drive Number>]

  -d <Raspberry Pi's Drive Number>: To find this, you can run 'diskutil list'.
                                    ex: /dev/disk<Drive Number>

                                    **If only one drive is present with a Linux partition
                                    this parameter does not need to be specified
  "
  exit
}


while getopts d:h o; do
  case $o in
    (d) VOLUME_NUMB=${OPTARG};;
    (h) usage;;
    (*) usage;
  esac
done

if [ -z $VOLUME_NUMB ]; then

  NUMB_LINUX_PARTITIONS=$(diskutil list | grep -o Linux | tr "\r" "\n" | wc -l)

  if [ $NUMB_LINUX_PARTITIONS -ge 2 ]; then

    echo "More than one Linux partition is present.
          Please specify a Drive Number with the -d parameter."

    exit
  elif [ $NUMB_LINUX_PARTITIONS -le 0 ]; then

    echo "Please insert Raspberry Pi's SD card and try again"

    exit
  fi

  VOLUME_NUMB=$(diskutil list | grep Linux |sed -e 's/.*disk\(.*\)s.*/\1/')

else
  CHECK_VOLUME_NUMB = $(diskutil list | grep "Linux" | grep "disk${VOLUME_NUMB}"\
                        | tr "\r" "\n" | wc -l)
  if [ $CHECK_VOLUME_NUMB -le 0 ]; then

    echo "Please check the provided volume number and
          provide a volume number that has a Linux partition associated with it"

  fi

fi

VOLUME="/dev/disk${VOLUME_NUMB}" 

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

#sudo is not required for this command
#I just added it to ask for password before unmounting
echo "WARNING: This script unmounts the Raspberry Pi's SD card to be able to emulate it"
sudo diskutil unmountDisk ${VOLUME}

#sudo is required for qemu-system-******* command
#BULLSEYE WORKING
  sudo qemu-system-aarch64 \
  -M versatilepb \
  -cpu arm1176 \
  -m 256 \
  -drive file=${VOLUME},format=raw \
  -dtb ${SCRIPT_DIR}/qemu-rpi-kernel/versatile-pb-bullseye-5.10.63.dtb \
  -kernel ${SCRIPT_DIR}/qemu-rpi-kernel/kernel-qemu-5.10.63-bullseye \
  -append 'root=/dev/sda2' \
  -netdev vmnet-bridged,id=vmnet,ifname=en0 \
  -device virtio-net-pci,netdev=vmnet \
  -nographic \