Opció 2 : Fer servir un fitxer 'preseed'
--------------------------------------------

L'instal·lador de Debian es pot personalitzar simplement creant un fitxer *preseed* amb les respostes a les preguntes ([Documentació](https://help.ubuntu.com/16.04/installation-guide/i386/apbs04.html)).

Segurament aquest opció és la més "correcta" ja que fa servir l'instal·lador de Debian que és la base de l'instal·lador de Ubuntu.

### Procediment per crear el CD

#### 1. Posar els fitxers en un directori temporal 

Ès exactament el mateix que en la opció anterior:

    # mkdir -p /mnt/iso
    # mount -o loop ubuntu.iso /mnt/iso
    # mkdir -p /opt/ubuntuiso 
    # cp -rT /mnt/iso /opt/ubuntuiso

#### 2. Generar les respostes

Generem un fitxer amb les respostes seguint el tutorial ([Documentació](https://help.ubuntu.com/16.04/installation-guide/i386/apbs04.html)): 

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

    ### Partició de disc amb carpeta /home a part.
    d-i partman-auto/method string lvm
    d-i partman-lvm/device_remove_lvm boolean true
    d-i partman-lvm/confirm boolean true
    d-i partman-auto/choose_recipe select home

    d-i partman/confirm_write_new_label boolean true
    d-i partman/confirm_nooverwrite boolean true
    d-i partman/choose_partition select finish
    d-i partman/confirm boolean true

    d-i partman-lvm/confirm boolean true
    d-i partman-lvm/confirm_nooverwrite boolean true
    d-i partman-auto-lvm/guided_size string max

    ### Usuari per defecte (potser hauria de xifrar la contrasenya)
    d-i passwd/user-fullname string Usuari pelat
    d-i passwd/username string usuari
    #d-i passwd/user-password password patata
    #d-i passwd/user-password-again password patata
    d-i passwd/user-password-crypted password $6$Z2WoBEMQnL5cMx$.2C0ttvnfFyS3hiDrUlIuEGE6r35vjAVec7zIS07FM8zcZuzezNfZicEXa3A/NxMm91q1FRrxYQJLCa8hyIVs1
    d-i user-setup/encrypt-home boolean false
    d-i user-setup/allow-password-weak boolean true

    ### Paquets i repositoris
    d-i mirror/country string ES
    d-i mirror/http/proxy string
    d-i apt-setup/restricted boolean true
    d-i apt-setup/universe boolean true
    d-i pkgsel/install-language-support boolean true
    d-i pkgsel/ignore-incomplete-language-support boolean true

    # Xubuntu i servidor SSH
    d-i pkgsel/include string xubuntu-desktop openssh-server
    d-i pkgsel/update-policy select none

    ### Boot loader installation
    d-i grub-installer/only_debian boolean true
    d-i grub-installer/with_other_os boolean false
    d-i grub-installer/password password patata
    d-i grub-installer/password-again password patata

    ### Finishing up the installation
    d-i finish-install/reboot_in_progress note

La contrasenya la he xifrat fent servir *mkpasswd* però també es pot posar en planer

    mkpasswd -m sha-512 contrasenya

Els paquets els afegeixo amb *pkgsel/include*. En aquest cas instal·lo Xubuntu i el servidor OpenSSH:

    d-i pkgsel/include string xubuntu-desktop openssh-server

Mentres feia proves he descobert com es pot fer perquè crei automàticament la partició arrel, swap i home: 

    d-i partman-auto/choose_recipe select home

Aquest sistema permet posar contrasenya a Grub automàticament (en el fitxer hi he posat 'patata' sense xifrar però es pot posar la contrasenya xifrada)

### 3. Modificar el menú d'arrencada

S'ha de modificar la opció del menú d'arrancada, isolinux/txt.cfg, perquè agafi el fitxer amb la resposta (modificant la opció append). 

El fitxer amb les respostes es pot carregar des de http o ftp (preseed/url): 

    default install
    label install
      menu label ^Install Ubuntu Server
      kernel /install/vmlinuz
      append preseed/url=http://192.168.88.225/preseed.cfg debian-installer/locale=ca_ES netcfg/choose_interface=auto initrd=/install/initrd.gz priority=critical --

En aquest cas la configuració es carrega des d'un servidor web. L'instal·lador se la descarregarà quan la necessiti per poder tenir les respostes i no haver-les de demanar.

Ho hauria pogut fer posant el fitxer en el CD i canviar la línia append per (presed/file): 

    append preseed/file=/cdrom/preseed.cfg debian-installer/locale=ca_ES netcfg/choose_interface=auto initrd=/install/initrd.gz priority=critical --

#### 4. Generar la ISO 

Només queda generar la ISO: 

    # mkisofs -D -r -V "ATTENDLESS_UBUNTU" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o /opt/autoinstall.iso /opt/ubuntuiso

####  Provar

Es posa el CD en una màquina i el procés d'instal·lació es farà sense cap pregunta. Tot acabarà amb el sistema instal·lat amb Xubuntu, amb l'usuari 'usuari' i el servidor SSH. 

![Xubuntu](../imatges/xubuntu.png)
