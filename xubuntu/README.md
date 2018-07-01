Modificar CD de Xubuntu Live CD
===============================

Problema inicial al seguir les instruccions d'Ubuntu
----------------------------------------------------------
El problema està en que fan servir un instal·lador anomenat Ubiquity i tots els intents per automatizar la instal·lació, per ara, han acabat com el rosari de l'Aurora:

* No s'automatitza la instal·lació (no es pot escapar de la pantalla inicial)
* Quan he aconseguit que s'instal·li sense demanar res, no arranca el sistema...

![fail](../imatges/fail.png)

Després de moltes proves he trobat que el problema està en fer les particions amb LVM. Sembla que Ubuntu Server no hi té cap problema però les versions Desktop NO FUNCIONEN.

Canviant el pressed per: 

    d-i partman-auto/method string regular

Ha solucionat el problema immediatament.

Solucions
----------------------------

Però no n'hi ha prou, amb sistemes basats en UEFI tenim un problema nou. Per tant tenim dos camins:

* [BIOS Sense EFI](NoEFI.md)
* [BIOS i EFI](EFI.md)

Un cop generada la imatge ISO, es posa el CD en una màquina i el procés d'instal·lació es farà sense cap pregunta:

- Sistema instal·lat amb Xubuntu
- usuari 'usuari' 
- servidor SSH. 
- Grub protegit amb contrasenya

Sense cap mena de dubte és el millor sistema. 

