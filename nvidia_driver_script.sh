#!/usr/bin/env bash

printf "\n\n----------------------------------------------------------------\nPropriatery NVIDIA Driver Installation Script\n----------------------------------------------------------------\n\n\n"

while true; do
    read -p "Did you run 'sudo dnf update' and rebooted? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Please do so and try again..."; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

if ! runlevel | grep -q "3" ; then
   printf "You are not in runlevel 3. Run:\n    sudo systemctl set-default multi-user.target\n    sudo reboot\n"
   exit;
fi


version=`curl https://www.nvidia.com/object/unix.html | grep "Latest Long Lived Branch Version" | grep -Eo '[0-9][0-9][0-9]\.[0-9]?[0-9]?[0-9]' | head -1`
if [ ! -f ./$version.run ]; then
    printf "\n\n----------------------------------------------------------------\nDownloading NVIDIA driver version: $version\n----------------------------------------------------------------\n"
    curl -o $version.run http://us.download.nvidia.com/XFree86/Linux-x86_64/$version/NVIDIA-Linux-x86_64-$version.run
fi

chmod +x $version.run

printf "\n\n----------------------------------------------------------------\nInstalling dependencies...\n----------------------------------------------------------------\n"
sudo dnf install kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig

printf "\n\n----------------------------------------------------------------\nChecking noveau blacklisting...\n----------------------------------------------------------------\n"

if [ ! -f /etc/modprobe.d/blacklist.conf ]; then
    printf "File /etc/modprobe.d/blacklist.conf not found! Make sure to blacklist noveau using: \n"
    printf "echo 'blacklist nouveau' | sudo tee --append /etc/modprobe.d/blacklist.conf\n"
else
    if grep -q 'blacklist nouveau' /etc/modprobe.d/blacklist.conf; then
        :
    else
        printf "File /etc/modprobe.d/blacklist.conf found but no blacklisting entry exists! Make sure to blacklist noveau using: \n"
        printf "echo 'blacklist nouveau' | sudo tee --append /etc/modprobe.d/blacklist.conf\n"
        exit;
    fi
fi

if grep -q 'rd.driver.blacklist=nouveau' /etc/sysconfig/grub; then
    :
else
    printf "File /etc/sysconfig/grub found but no blacklisting exists! Make sure to blacklist noveau by appending 'rd.driver.blacklist=nouveau' to the end of the 'GRUB_CMDLINE_LINUX=\"...\'. Example:\nGRUB_CMDLINE_LINUX=\"rd.lvm.lv=fedora/swap rd.lvm.lv=fedora/root rhgb quiet rd.driver.blacklist=nouveau\"\n"
    printf "1. Edit using:\n    sudo vi /etc/sysconfig/grub\n"
    printf "2. Run:\n    grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg\n"
    exit;
fi

printf "\n\n----------------------------------------------------------------\nRemoving noveau driver...\n----------------------------------------------------------------\n"
sudo dnf remove xorg-x11-drv-nouveau

printf "\n\n----------------------------------------------------------------\nBacking up old initramfs...\n----------------------------------------------------------------\n"
sudo mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-nouveau.img

printf "\n\n----------------------------------------------------------------\nCreating new initramfs...\n----------------------------------------------------------------\n"
sudo dracut /boot/initramfs-$(uname -r).img $(uname -r)

printf "\n\n----------------------------------------------------------------\nInstalling NVIDIA drivers...\n----------------------------------------------------------------\n"

###########################################################
sudo ./$version.run -a -q -X --dkms

if [ $? -ne 0 ] ; then
    printf "\n\n\n\n!!!!!!!!!!!!!!!!Installation failed!!!!!!!!!!!!!!!!\n\n\n\n";
    exit;
fi
###########################################################

printf "\n\n----------------------------------------------------------------\nSetting to runlevel 5...\n----------------------------------------------------------------\n"
sudo systemctl set-default graphical.target

printf "\n\n----------------------------------------------------------------\nOptional stuff...\n----------------------------------------------------------------\n"
while true; do
    read -p "Do you want to install video acceleration support for video players?" yn
    case $yn in
        [Yy]* ) sudo dnf install vdpauinfo libva-vdpau-driver libva-utils ; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

printf "\n\n----------------------------------------------------------------\nRebooting in 10s...\n----------------------------------------------------------------\n"
sleep 10s
sudo reboot

