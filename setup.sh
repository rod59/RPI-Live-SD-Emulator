#! /bin/bash

# Install Xcode command line tools
xcode-select -p 1>/dev/null 2>/dev/null
checkXcode=$?
if [ $checkXcode != 0 ]; then
  echo
  echo "Please install Xcode command line tools first using"
  echo "$(tput setaf 6)xcode-select --install$(tput sgr0)"
  echo
  exit 1
fi

# Install Homebrew arm64
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$(logname)/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install necessary packages for building
brew install libffi gettext glib pkg-config autoconf automake pixman ninja

#Clean and (re)download qemu
rm -rf qemu && git clone https://github.com/qemu/qemu.git

#Remove the power of 2 check for sd cards
sed -i '' "/!is_power_of_2(blk_size)/,/}/d" qemu/hw/sd/sd.c

# Building qemu installer
mkdir qemu/build && cd qemu/build
../configure --target-list=aarch64-softmmu
make -j8

# Install qemu
sudo make install

# Cleaning up
cd ../../ && rm -rf qemu

#Clean and (re)download rpi kernels
rm -rf qemu-rpi-kernel && git clone https://github.com/dhruvvyas90/qemu-rpi-kernel.git 

