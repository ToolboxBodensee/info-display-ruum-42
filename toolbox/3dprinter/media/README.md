 3D Printer movies go in this folder
===============================

Since this should run on a Raspberry Pi it would override this files on the SD Card quit offten. This would degrade the SD Card quite quickly. To avoid this you should use a tmpfs (ramdisk) for this folder (and make sure you have enough RAM!).

For the ramdisk add the following line to /etc/fstab:
tmpfs /home/pi/infobeamer-tb/toolbox/3dprinter/bilder/ tmpfs defaults 0 0

