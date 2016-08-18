#/bin/bash
mkisofs -D -r -V "ATTENDLESS_UBUNTU" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o /home/xavier/autoinstall.iso /home/xavier/work-random/ubuntu-iso/iso

