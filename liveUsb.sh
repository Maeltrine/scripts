#TEST
X = $1
echo "BUILDING LIVE USB on /dev/sd$X"

echo "> clean up..."
sudo umount /tmp/usb-efi /tmp/usb-live /tmp/usb-persistence /tmp/live-iso >/dev/null 2>&1
sudo rm -rf /tmp/usb-efi /tmp/usb-live /tmp/usb-persistence /tmp/live-iso >/dev/null 2>&1

echo "> partitioning..."
sudo hdparm -r0 /dev/sd$X
sudo parted /dev/sd$X --script mktable gpt
sudo parted /dev/sd$X --script mkpart EFI fat32 1MiB 10MiB
sudo parted /dev/sd$X --script mkpart live fat32 10MiB 5GiB
sudo parted /dev/sd$X --script mkpart persistence ext4 5GiB 100%
sudo parted /dev/sd$X --script set 1 msftdata on
sudo parted /dev/sd$X --script set 2 legacy_boot on
sudo parted /dev/sd$X --script set 2 msftdata on

echo "> formating..."
sudo mkfs.vfat -n EFI /dev/sd${X}1 >/dev/null 2>&1
sudo mkfs.vfat -n LIVE /dev/sd${X}2 >/dev/null 2>&1
sudo mkfs.ext4 -n DATA -F -L persistence /dev/sd${X}3

echo "> mounting disks..."
sudo mkdir /tmp/usb-efi /tmp/usb-live /tmp/usb-persistence /tmp/live-iso
sudo mount /dev/sd${X}1 /tmp/usb-efi
sudo mount /dev/sd${X}2 /tmp/usb-live
sudo mount /dev/sd${X}3 /tmp/usb-persistence
sudo mount -oro live.iso /tmp/live-iso

echo "> setting up persistence..."
cp -ar /tmp/live-iso/* /tmp/usb-live

sudo echo "/ union" > /tmp/usb-persistence/persistence.conf

echo "> installing bootloaders..."
sudo grub-install --target=x86_64-efi --boot-directory=/tmp/usb-live/boot/ --efi-directory=/tmp/usb-efi /dev/sd$X --removable
sudo dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/mbr/gptmbr.bin of=/dev/sd$X
sudo syslinux --install /dev/sd${X}2

sudo mv /tmp/usb-live/isolinux /tmp/usb-live/syslinux
sudo mv /tmp/usb-live/syslinux/isolinux.bin /tmp/usb-live/syslinux/syslinux.bin
sudo mv /tmp/usb-live/syslinux/isolinux.cfg /tmp/usb-live/syslinux/syslinux.cfg

sudo sed --in-place 's#isolinux/splash#syslinux/splash#' /tmp/usb-live/boot/grub/grub.cfg
sudo sed --in-place '0,/boot=live/{s/\(boot=live .*\)$/\1 persistence/}' /tmp/usb-live/boot/grub/grub.cfg /tmp/usb-live/syslinux/menu.cfg
sudo sed --in-place '0,/boot=live/{s/\(boot=live .*\)$/\1 keyboard-layouts=us,uk locales=en_US.UTF-8/}' /tmp/usb-live/boot/grub/grub.cfg /tmp/usb-live/syslinux/menu.cfg

sudo umount /tmp/usb-efi /tmp/usb-live /tmp/usb-persistence /tmp/live-iso >/dev/null 2>&1
sudo rm -rf /tmp/usb-efi /tmp/usb-live /tmp/usb-persistence /tmp/live-iso >/dev/null 2>&1
