#!/bin/bash

clear

if [ $EUID -ne 0 ]; then
	echo "You must run this script as root"
	echo "Example: sudo $0"
	exit
fi

whiptail --yesno "This will install the required packages for LIRC and configure it.
Do you want to continue?" 0 0 3>&1 1>&2 2>&3
_t=$?

if [ $_t -eq 1 ]; then
	echo "Exiting as requested."
	exit
fi

whiptail --msgbox "This part will install LIRC and all dependencies.
Make sure you are connected to the internet.

During the installation LIRC will ask what type of IR Remote you have,
answer None to all questions. I'll handle it for you" 0 0

apt-get update
apt-get -y install lirc

# Configure LIRC for ODROID Hardware
hwconf=/etc/lirc/lirc_options.conf
sed -i "s/^driver.*=.*/driver\t\t=\ default/g" $hwconf
sed -i "s/^device.*=.*/device\t\t=\ \/dev\/lirc0/g" $hwconf
sed -i "s/^.*modinit.*/[modinit]/g" $hwconf
sed -i "s/^.*code\ .*=.*/code\ =\ \/sbin\/modprobe\ gpio-ir-recv/g" $hwconf
sed -i "s/^.*code1\ .*=.*/code1\ =\ \/sbin\/modprobe\ gpioplug-ir-recv\ gpio_nr=24\ active_low=1/g" $hwconf
sed -i "s/^.*lircd-uinput.*/[lircd-uinput]/g" $hwconf
sed -i "s/^.*add-release-events.*=.*/add-release-events\ =\ True/g" $hwconf
sed -i "s/^.*release-timeout.*=.*/release-timeout\ =\ 50/g" $hwconf
sed -i "s/^.*release-suffix.*=.*/release-suffix\ =\ _EVUP/g" $hwconf

whiptail --yesno "LIRC is partially configured.
We don't have a Remote IR configured. 

I can configure for Hardkernel's default IR Remote

Should I do it? (You can configure your own remote later)" 0 0 3>&1 1>&2 2>&3

if [ $_t -eq 0 ]; then
cat>/etc/lirc/lircd.conf.d/lircd.conf<<__EOF
begin remote
  name  odroid1.conf
  bits           16
  flags SPACE_ENC|CONST_LENGTH
  eps            30
  aeps          100
  header       8959  4566
  one           508  1737
  zero          508   600
  ptrail        507
  repeat       8959  2291
  pre_data_bits   16
  pre_data       0x4DB2
  gap          108299
  toggle_bit_mask 0x0
      begin codes
          KEY_POWER                0x3BC4
          KEY_MUTE                 0x11EE
          KEY_HOME                 0x41BE
          KEY_UP                   0x53AC
          KEY_DOWN                 0x4BB4
          KEY_LEFT                 0x9966
          KEY_RIGHT                0x837C
          KEY_ENTER                0x738C
          KEY_BACK                 0x59A6
          KEY_VOLUMEDOWN           0x817E
          KEY_VOLUMEUP             0x01FE
          KEY_MENU                 0xA35C
      end codes
end remote
__EOF
fi

whiptail --msgbox "We are done here.
Please reboot for the changes take effect." 0 0
