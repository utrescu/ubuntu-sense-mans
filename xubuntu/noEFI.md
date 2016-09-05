Creació del CD
---------------------
### 1. Fer una còpia temporal del CD

Com sempre es copien els arxius en local per poder modificar-los i fer una ISO nova: 

    # mkdir /mnt/cdrom
    # sudo mount -o loop xubuntu-16.04.1-desktop-amd64.iso /mnt/iso
    # mkdir /opt/iso
    # cp -rT /mnt/iso /opt/iso 

### 2. Modificar els fitxers d'arrencada

Són els mateixos de les opcions anteriors. Per exemple es canvia el timeout del fitxer '/opt/iso/isolinux/isolinux.cfg' perquè no calgui prémer return per iniciar la instal·lació 

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

### 3. Crear les respostes

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

#### 4. Generar la ISO i provar-ho

Només queda generar la ISO: 

    # mkisofs -D -r -V "ATTENDLESS_UBUNTU" -cache-inodes -J -l \ 
        -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \ 
        -boot-load-size 4 -boot-info-table -o /opt/autoinstall.iso /opt/iso
