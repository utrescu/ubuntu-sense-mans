Creació del CD amb suport EFI i BIOS
=======================================

1. Fer una còpia temporal del CD
----------------------------------

Com sempre es copien els arxius en local per poder modificar-los i fer una ISO nova: 

    # mkdir /mnt/cdrom
    # sudo mount -o loop xubuntu-16.04.1-desktop-amd64.iso /mnt/iso
    # mkdir /opt/iso
    # cp -rT /mnt/iso /opt/iso 

2. Modificar els fitxers d'arrencada per BIOS
-------------------------------------------------

No s'ha de canviar gaire res, només es canvia el timeout del fitxer '/opt/iso/isolinux/isolinux.cfg' perquè no calgui prémer return per iniciar la instal·lació en mode BIOS

    path 
    include menu.cfg
    default vesamenu.c32
    prompt 0
    timeout 10
    ui gfxboot bootlogo

Es modifica el fitxer *txt.cfg* del mateix directori per fer que la instal·lació sigui la opció per defecte, *default* serà *live-install*, i es canvien els paràmetres d'arrencada del *live-install* (deixo el teclat americà perquè com que no respondré cap pregunta ... )

    default live-install
    label live-install
      menu label ^Install Xubuntu
      kernel /casper/vmlinuz.efi
      append auto file=/cdrom/xubuntu.cfg keyboard-configuration/layoutcode=us and console-setup/ask_detect=false boot=casper automatic-ubiquity noprompt initrd=/casper/initrd.lz ---

3. Modificar fitxers d'arrencada per UEFI
---------------------------------------------

Resulta que els sistemes amb UEFI no fan servir isolinux per arrancar sinó que fan servir Grub. Per això per aquests sistemes s'ha de modificar *grub.cfg* i posar-hi les opcions d'arrancada del kernel.

Per exemple afegir `set timeout=1` fa que no calgui prémer return: 

    if loadfont /boot/grub/font.pf2 ; then
        set gfxmode=auto
        insmod efi_gop
        insmod efi_uga
        insmod gfxterm
        terminal_output gfxterm
    fi

    set menu_color_normal=white/black
    set menu_color_highlight=black/light-gray
    set timeout=1
    set default=0

    menuentry "Install automatic" {
            set gfxpayload=keep
        linux	/casper/vmlinuz.efi  file=/cdrom/xubuntu.cfg boot=casper auto automatic-ubiquity noprompt quiet ---
            initrd /casper/initrd.lz
    }
    ...

4. Crear les respostes
--------------------------

En aquesta opció el fitxer de respostes tindrà unes opcions especials *ubiquity* que són per les opcions específiques de l'instal·lador d'Ubuntu que no estan en el Debian Installer.

Per algun motiu la instal·lació extra de paquets amb el sistema de Debian no funciona (amb els altres sistemes anava...) però ara aquesta línia ha estat totalment ignorada:

    d-i pkgsel/include string openssh-server

Per poder instal·lar el servidor OpenSSH ho he hagut de fer en un script de post instal·lació d'Ubiquity (s'hi pot afegir el que faci falta):

    ubiquity ubiquity/success_command string \
    in-target apt-get -y install openssh-server;

El fitxer de respostes xubuntu.cfg tindrà una forma semblant a aquesta: 

    # Respostes de Ubiquity (Ubuntu installer)
    ubiquity languagechooser/language-name select Català
    ubiquity countrychooser/shortlist select ES
    ubiquity time/zone   select  Europe/Madrid
    ubiquity debian-installer/locale select  ca_ES.UTF-8
    ubiquity localechooser/supported-locales multiselect en_US.UTF-8, ca_ES.UTF-8
    ubiquity console-setup/ask_detect    boolean false
    ubiquity keyboard-configuration/layoutcode   select  es
    console-setup   console-setup/layoutcode    string  es

    ubiquity ubiquity/summary note

    ubiquity ubiquity/reboot boolean true

    d-i debian-installer/locale string ca_ES.UTF8
    d-i localechooser/supported-locales multiselect ca_ES.UTF-8, en_US.UTF-8

    # Teclat
    d-i console-setup/ask _detect boolean false
    d-i console-setup/layoutcode es
    d-i keyboard-configuration/modelcode string pc105
    d-i keyboard-configuration/layoutcode string es
    d-i keyboard-configuration/variantcode string cat

    ### Configuració de la xarxa
    d-i netcfg/choose_interface select auto
    d-i netcfg/wireless_wep string

    ### Mirror (no tinc clar que calgui)
    choose-mirror-bin mirror/http/proxy string

    ### Sincronitza rellotges
    d-i clock-setup/utc boolean true
    d-i time/zone string Europe/Madrid
    d-i clock-setup/ntp boolean true

    ### Evitar que faci preguntes si ja hi ha una partició
    d-i preseed/early_command string umount /media

    ### Partició de disc amb carpeta /home en una partició a part.
    d-i partman-auto/method string regular
    d-i partman-lvm/device_remove_lvm boolean true
    d-i partman-lvm/confirm boolean true
    d-i partman-auto/choose_recipe select home
    d-i partman/default_filesystem string ext4

    d-i partman/confirm_write_new_label boolean true
    d-i partman/confirm_nooverwrite boolean true
    d-i partman/choose_partition select finish
    d-i partman/confirm boolean true

    d-i partman-lvm/confirm boolean true
    d-i partman-lvm/confirm_nooverwrite boolean true
    d-i partman-auto-lvm/guided_size string max

    ### Creació del compte d'usuari 'usuari'
    d-i passwd/user-fullname string Usuari pelat
    d-i passwd/username string usuari
    #d-i passwd/user-password password patata
    #d-i passwd/user-password-again password patata
    d-i passwd/user-password-crypted password $6$Z2WoBEMQnL5cMx$.2C0ttvnfFyS3hiDrUlIuEGE6r35vjAVec7zIS07FM8zcZuzezNfZicEXa3A/NxMm91q1FRrxYQJLCa8hyIVs1
    d-i user-setup/encrypt-home boolean false
    d-i user-setup/allow-password-weak boolean true

    ### Definir els repositoris
    d-i mirror/country string ES
    d-i mirror/http/proxy string
    d-i apt-setup/restricted boolean true
    d-i apt-setup/universe boolean true
    d-i pkgsel/install-language-support boolean true
    d-i pkgsel/ignore-incomplete-language-support boolean true

    ### Instal·lació de paquets 
    # Install the Xubuntu desktop.
    tasksel	tasksel/first	multiselect xubuntu-desktop
    d-i	pkgsel/language-pack-patterns	string
    
    ubiquity ubiquity/success_command string \
      in-target apt-get -y install openssh-server;
    
    d-i pkgsel/upgrade select none
    d-i pkgsel/update-policy select unattended-upgrades

    ### Instal·lació de Grub 

    d-i grub-installer/only_debian boolean true
    d-i grub-installer/with_other_os boolean false
    d-i grub-installer/password password patata
    d-i grub-installer/password-again password patata
    # or encrypted using an MD5 hash, see grub-md5-crypt(8).
    #d-i grub-installer/password-crypted password [MD5 hash]
    d-i grub-installer/bootdev  string default

    ### Finishing up the installation
    d-i finish-install/reboot_in_progress note
    ubiquity ubiquity/reboot boolean true
    ubiquity ubiquity/poweroff boolean true

I com que en la configuració he posat que les respostes estaran en el CD hi copio el fitxer xubuntu.cfg a l'arrel 

    # cp xubuntu.cfg /opt/iso

5. Generar la ISO i provar-ho
--------------------------------------

Segons molts tutorials per generar la ISO n'hi hauria d'haver prou amb això:

    # mkisofs -r -U -V "Custom" -cache-inodes -J -joliet-long -v -T \ 
      -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \ 
      -boot-load-size 4 -boot-info-table -eltorito-alt-boot \ 
      -e boot/grub/efi.img -no-emul-boot -o /opt/xautomount2.iso /opt/iso

Es pot comprovar que la ISO generada té suport de UEFI:

    # dumpet -i /opt/xautomount2.iso 
    Validation Entry:
        Header Indicator: 0x01 (Validation Entry)
        PlatformId: 0x00 (80x86)
        ID: ""
        Checksum: 0x55aa
        Key bytes: 0x55aa
    Boot Catalog Default Entry:
        Entry is bootable
        Boot Media emulation type: no emulation
        Media load segment: 0x0 (0000:7c00)
        System type: 0 (0x00)
        Load Sectors: 4 (0x0004)
        Load LBA: 184 (0x000000b8)
    Section Header Entry:
        Header Indicator: 0x91 (Final Section Header Entry)
        PlatformId: 0xef (EFI)
        Section Entries: 1
        ID: ""
    Boot Catalog Section Entry:
        Entry is bootable
        Boot Media emulation type: no emulation
        Media load address: 0 (0x0000)
        System type: 0 (0x00)
        Load Sectors: 4736 (0x1280)
        Load LBA: 204 (0x000000cc)

El problema està en que si es fa servir aquesta ISO en un CD o DVD funciona però si es passa a un USB **no arranca de cap forma**. 

Per poder fer servir la ISO en un USB i que funcioni s'ha d'afegir un MBR:  

> ISO 9660 filesystems which are created by the mkisofs will boot via BIOS firmware, but only from optical media like CD, DVD, or BD.
> The isohybrid feature enhances such filesystems by a Master Boot Record (MBR) for booting via BIOS from disk storage devices like USB flash drives.

Per tant cal fer servir isohybrid. El més fàcil és recuperar el MBR de la ISO del CD d'instal·lació de Xubuntu:

    $ sudo dd if=ubuntu-16.04-desktop-amd64.iso bs=512 count=1 of=/opt/iso/isolinux/isohdpfx.bin

I genero la ISO amb xorriso (no és conya): 

    $ cd /opt/iso
    $ sudo xorriso -as mkisofs -r -J -joliet-long -l -cache-inodes \
      -isohybrid-mbr isolinux/isohdpfx.bin \ 
      -c isolinux/boot.cat -b isolinux/isolinux.bin \ 
      -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot \ 
      -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat \ 
      -o /opt/xautomount2.iso .

Es pot comprovar que hi ha dues particions en la ISO: 

    $ sudo fdisk -lu xautomount2.iso
    Disk xautomount2.iso: 1,2 GiB, 1265106944 bytes, 2470912 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0x37bc4635

    Dispositiu         Arrencada Start   Final Sectors  Size Id Tipus
    xautomount2.iso1 *               0 2470911 2470912  1,2G  0 Buida
    xautomount2.iso2               716    5451    4736  2,3M ef EFI (FAT-12/16/32)

Es pot comprovar que les característiques de la ISO són les mateixes que les del CD original de Xubuntu fent servir **isoinfo**: 

    $ isoinfo -d -i xautomount2.iso 
    CD-ROM is in ISO 9660 format
    System id: 
    Volume id: ISOIMAGE
    Volume set id: 
    Publisher id: 
    Data preparer id: XORRISO-1.4.4 2016.07.01.140001, LIBISOBURN-1.4.4, LIBISOFS-1.4.4, LIBBURN-1.4.4
    Application id: 
    Copyright File id: 
    Abstract File id: 
    Bibliographic File id: 
    Volume set size is: 1
    Volume set sequence number is: 1
    Logical block size is: 2048
    Volume size is: 617728
    El Torito VD version 1 found, boot catalog is in sector 178
    Joliet with UCS level 3 found
    Rock Ridge signatures version 1 found
    Eltorito validation header:
        Hid 1
        Arch 0 (x86)
        ID ''
        Key 55 AA
        Eltorito defaultboot header:
            Bootid 88 (bootable)
            Boot media 0 (No Emulation Boot)
            Load segment 0
            Sys type 0
            Nsect 4
            Bootoff 553 1363

Es pot obtenir més informació amb *dumpet* o *xorriso*: 

    # xorriso -indev xautomount2.iso -toc -pvd_info
    # dumpet -i xautomount2.iso 

Després es grava aquesta imatge a un USB i ... 

> TO BE CONTINUED