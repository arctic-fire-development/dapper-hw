## pcDuino3 installation

### setup dev platform
1. install cross-compile toolchain
    - ```sudo apt-get install gcc-arm-linux-eabihf g++-arm-linux-eabihf```
2. install kermit
    - ```sudo apt-get install ckermit```
3. download u-boot, kernel, rootfs, and wireless driver
    - ```git clone https://github.com/jwrdegoede/u-boot-sunxi.git  -b sunxi-next```
        - this is the A20 dual-cpu support (PSCI) until it is added to the main repo at https://github.com/linux-sunxi/u-boot-sunxi
    - ```git clone https://github.com/linux-sunxi/linux-sunxi -b sunxi-next```
    - ```wget http://releases.linaro.org/14.08/ubuntu/trusty-images/nano/linaro-trusty-nano-20140821-681.tar.gz```
    - ```git clone https://github.com/lwfinger/rtl8188eu```
4. if on OS X
    - you will need the drivers for the usb-tty device
        - ```git clone https://github.com/changux/pl2303osx.git```
        - double click PL2303_Serial-USB_on_OSX_Lion.pkg
    - install kermit from here:
        - [kermit](http://www.kermitproject.org/ck90.html#source)
    - setup .kermrc
        - replace /dev/tty.PL2303-00001014 with whatever it shows up as in /dev
        - ```bash
            set line /dev/tty.PL2303-00001014
            set speed 115200
            set carrier-watch off
            set handshake none
            set flow-control none
            robust
            set file type bin
            set file name lit
            set rec pack 1000
            set send pack 1000
            set window 5
            set prompt Kermit>
            ```

### prep sd card
1. insert >4GB into computer
2. use dmesg or similar to get the device location (/dev/sdc or /dev/mmcblk0, etc)
    - ```CARD=/dev/sdc```
3. unmount it
4. format with gparted or similar
    - be sure to have dos partition table created
5. ensure it is still unmounted
6. make new partitions
    ```bash
    # fdisk ${CARD}

    Command (m for help): n
    Partition type:
       p   primary (0 primary, 0 extended, 4 free)
       e   extended
    Select (default p): p
    Partition number (1-4, default 1): 1
    First sector (2048-15523839, default 2048): 2048
    Last sector, +sectors or +size{K,M,G} (2048-15523839, default 15523839): +15M

    Command (m for help): n
    Partition type:
       p   primary (1 primary, 0 extended, 3 free)
       e   extended
    Select (default p): p
    Partition number (1-4, default 2): 2
    First sector (32768-15523839, default 32768): 32768
    Last sector, +sectors or +size{K,M,G} (32768-15523839, default 15523839): +240M

    Command (m for help): p

    Disk /dev/mmcblk0: 7948 MB, 7948206080 bytes
    4 heads, 16 sectors/track, 242560 cylinders, total 15523840 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk identifier: 0x17002d14

            Device Boot      Start         End      Blocks   Id  System
    /dev/mmcblk0p1            2048       32767       15360   83  Linux
    /dev/mmcblk0p2           32768      524287      245760   83  Linux

    Command (m for help): w
    The partition table has been altered!

    Calling ioctl() to re-read partition table.
    ```
7. format partitions
    - ```sudo mkfs.vfat /dev/mmcblk0p1```
        - use /dev/sdc1 or similar if base device is sdc
    - ```sudo mkfs.ext4 /dev/mmcblk0p2```
        - use /dev/sdc2 or similar if base device is sdc

### compile u-boot
1. ```cd u-boot-sunxi```
2. ```mkdir build```
3. ```make CROSS_COMPILE=arm-linux-gnueabihf- Linksprite_pcDuino3_config O=build```
4. ```make CROSS_COMPILE=arm-linux-gnueabihf- O=build```
5. ```cd build```
6. ```sudo dd if=u-boot-sunxi-with-spl.bin of=${CARD} bs=1024 seek=8```
7. create u-boot uEnv.txt
    - mount first partition
        - ```mkdir /mnt/vfat```
        - ```sudo mount -t vfat /dev/mmcblk0p1 /mnt/vfat```
    - create file ```sudo vim /mnt/vfat/uEnv.txt```
        -  ```vim
            fdt_high=ffffffff
            loadkernel=fatload mmc 0 0x46000000 uImage
            loaddtb=fatload mmc 0 0x49000000 dtb
            bootargs=console=ttyS0,115200 earlyprintk root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait
            uenvcmd=run loadkernel && run loaddtb && bootm 0x46000000 - 0x49000000
            ```

### compile linux kernel
0. ensure the sdcard partitions are mounted
    - ```mkdir /mnt/vfat /mnt/ext4```
    - ```sudo mount -t vfat /dev/sdc1 /mnt/vfat```
    - ```sudo mount -t ext4 /dev/sdc2 /mnt/ext4```
1. ```cd linux-sunxi```
2. verify you are in the sunxi-next branch
    - ```git status```
3. make build directory
    - ```mkdir build```
4. generate the .config file and add the following to the kernel
    - ```ARCH=arm CROSS_COMPILER=arm-linux-gnueabihf- make sunxi_defconfig O=build```
    - ```ARCH=arm CROSS_COMPILER=arm-linux-gnueabihf- make menuconfig O=build```
    - select the following
        - ```bash
        [*] Enable loadable module support  —>
        [*] Forced module loading
        [*] Module unloading
        [*] Forced module unloading
        [*] Module versioning support
        [*] Source checksum for all modules
        [*] Module signature verification
        [*] Require modules to be validly signed
        [*] Automatically sign all modules
        Which hash algorithm should modules be signed with? (Sign modules with SHA-1)
        ```
        - ```bash
        System Type —>
        [*] Allwinner SoCs —>
        [*]   Allwinner A20 (sun7i) SoCs support
        ```
        - ```bash
        [*] USB support —>
        <M> USB Mass Storage —>
        --- all as M
        [*] USB Serial Converter —>
        <M> USB Generic Serial Driver
        <M> USB FTDI
        [*] Staging —>
        <M> RTL8188EU
        <M> as AP
        ```
5. build the kernel, dtb
    - ```cd build```
    - ```COMPILE='ARCH=arm CFLAGS="-mcpu=cortex-a7 -mtune=cortex-a7 -mfloat-abi=hard -mfpu=vfpv4" CXXFLAGS="${CFLAGS}" CROSS_COMPILE=arm-linux-gnueabihf- LOADADDR=40008000'```
    - ```${COMPILE} make prepare```
    - ```${COMPILE} make modules_prepare```
    - ```${COMPILE} make uImage -j 8```
    - ```${COMPILE} make dtbs -j 8```
    - ```${COMPILE} make modules -j 8```

6. install kernel and dtb to first partition of sdcard
    - ```cp arch/arm/boot/uImage   /mnt/vfat/```
    - ```cp arch/arm/boot/dts/sun7i-a20-pcduino3.dtb /mnt/vfat/dtb```

7. install modules to the second partition
    - still inside the build directory
    - ```${COMPILE} make modules_install INSTALL_MOD_PATH=/mnt/ext4/```

8. ```cd ~```

### install rootfs
0. ensure the sdcard partitions are mounted (they should be from the previous steps)
    - ```sudo mount```
    - if not present, then
        - ```mkdir /mnt/vfat /mnt/ext4```
        - ```sudo mount -t vfat /dev/sdc1 /mnt/vfat```
        - ```sudo mount -t ext4 /dev/sdc2 /mnt/ext4```
1. ```sudo tar --strip-components=1 --show-transformed-names -C /mnt/ext4/ -zvxpf linaro-trusty-alip-20140821-681.tar.gz```

### os setup
- change wifi to be AP
    - to use wlan0 as a gateway, set wlan0 as static ip
        - ```sudo vim /etc/network/interfaces
        auto lo
        iface lo inet loopback
        auto wlan0
        iface wlan0 inet static
            address 192.168.2.1
            netmask 255.255.255.0
        ```
        - ```sudo apt-get install dnsmasq```
            - edit /etc/dnsmasq to have
              ```bash
              local=/localnet/
              address=/gcs/127.0.0.1
              interface=wlan0
              dhcp-range=wlan0,192.168.2.50,192.168.2.100,12h
              ```
    - build and install hostapd
        - ```git clone https://github.com/jenssegers/RTL8188-hostapd```
        - ```cd RTL8188-hostapd/hostapd```
        - ```sudo make```
        - ```sudo make install```
        - ```sudo update-rc.d hostapd defaults```
        - ```sudo update-rc.d hostapd enable```
    - modify hostapd config file
        - ```bash
        sudo vim /etc/hostapd/hostapd.conf
        interface=wlan0
        ssid=gcs
        hw_mode=g
        channel=6
        auth_algs=1
        wmm_enabled=0
        ```

### install gcs

references
http://forum.odroid.com/viewtopic.php?f=52&t=1674
