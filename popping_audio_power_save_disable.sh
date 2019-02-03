#!/usr/bin/env bash

printf "\n\n----------------------------------------------------------------\nPopping Audio Resolution Script (Audio Powersave Disable)\n----------------------------------------------------------------\n\n\n"

if ! cat /sys/module/snd_hda_intel/parameters/power_save | grep "1" ; then
   printf "Power-saving mode does not seem to be an issue of your sound card. Aborting...\n"
   exit;
fi

if [ ! -f /etc/modprobe.d/audio_disable_powersave.conf ]; then
    echo 'options snd_hda_intel power_save=0' | sudo tee --append /etc/modprobe.d/audio_disable_powersave.conf
else
    sudo rm /etc/modprobe.d/audio_disable_powersave.conf
    echo 'options snd_hda_intel power_save=0' | sudo tee --append /etc/modprobe.d/audio_disable_powersave.conf
fi

printf "\n\n----------------------------------------------------------------\nRebooting in 10s...\n----------------------------------------------------------------\n\n\n"

sudo reboot

