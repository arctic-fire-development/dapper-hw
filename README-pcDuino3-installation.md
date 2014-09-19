## pcDuino3 installation

### setup dev platform

1. install pre-reqs
    - ```sudo apt-get install -y $(cat build-system-apt-get-list.txt | awk '{print $1}')```
2. if in virtualbox, add the user to the vboxsf group
    - ```sudo usermod -a -G vboxsf wilsonrm```
    - re- login for changes to take effect
3. download u-boot, kernel, rootfs, wireless AP daemon, sunxi tools and boards
    - run ```./clone-repos.sh```
4. if on OS X
    - you will need the drivers for the usb-tty device
        - ```git clone https://github.com/changux/pl2303osx.git```
        - double click PL2303_Serial-USB_on_OSX_Lion.pkg
    - install kermit from here:
        - [kermit](http://www.kermitproject.org/ck90.html#source)
    - setup .kermrc
        - replace /dev/tty.PL2303-00001014 with whatever it shows up as in /dev
        ```bash
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

1.  insert >4GB into computer
2.  use dmesg or similar to get the device location (/dev/sdc or /dev/mmcblk0, etc)
    - ```CARD=/dev/sdc```
3.  unmount it
4.  format with gparted or similar
    - be sure to have dos partition table created
5.  ensure it is still unmounted
6.  make new partitions
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
7.  format partitions
    - ```sudo mkfs.vfat /dev/mmcblk0p1```
        - use /dev/sdc1 or similar if uSD card device is sdc
    - ```sudo mkfs.ext4 /dev/mmcblk0p2```
        - use /dev/sdc2 or similar if uSD card device is sdc

### build the board specific script.bin

script.bin is a file with very important configuration parameters like port GPIO assignments, DDR memory parameters, etc

1.  mount first partition
    - ```mkdir /mnt/vfat```
    - ```sudo mount -t vfat /dev/mmcblk0p1 /mnt/vfat```
2. ```cd sunxi-tools```
    - ```make fex2bin```
    - ```cp fex2bin ~/bin```
3. ```cd sunxi-boards/sys_config/a20```
    - ```cp linksprite_pcduino3.fex original-linksprite_pcduino3.fex```
    - edit linksprite_pcduino3.fex
        - for usbc0
        - change ```usb_port_type``` from 0 to 1 to make it a USB host
    - ```fex2bin linksprite_pcduino3.fex > script.bin```
4.  ```cp script.bin /mnt/sd```
5.  ```sync```
6.  ```umount /dev/sdX1```

### compile u-boot

1. ```cd u-boot-sunxi```
2. ```mkdir build```
3. ```make CROSS_COMPILE=arm-linux-gnueabihf- Linksprite_pcDuino3_config O=build```
4. ```make CROSS_COMPILE=arm-linux-gnueabihf- O=build```
5. ```cd build```
6. ```sudo dd if=u-boot-sunxi-with-spl.bin of=${CARD} bs=1024 seek=8```
7. copy over u-boot uEnv.txt
    - ```sudo cp ~/dapper-hw/uEnv.txt /mnt/vfat/uEnv.txt```

### compile linux kernel
1. ensure the sdcard partitions are mounted
    - ```mkdir /mnt/vfat /mnt/ext4```
    - ```sudo mount -t vfat /dev/sdc1 /mnt/vfat```
    - ```sudo mount -t ext4 /dev/sdc2 /mnt/ext4```
2. ```cd linux-sunxi```
3. verify you are in the sunxi-next branch
    - ```git status```
4. make build directory
    - ```mkdir build```
5. build the kernel (uImage), dtb, and modules
    - ```cd build```
    - copy the .config from dapper-hw
        - ```cp ~/dapper-hw/kernel.config ./.config```
    - ```COMPILE='ARCH=arm CFLAGS="-mcpu=cortex-a7 -mtune=cortex-a7 -mfloat-abi=hard -mfpu=vfpv4" CXXFLAGS="-mcpu=cortex-a7 -mtune=cortex-a7 -mfloat-abi=hard -mfpu=vfpv4" CROSS_COMPILE=arm-linux-gnueabihf- LOADADDR=40008000'```
    - ```${COMPILE} make prepare```
    - ```${COMPILE} make modules_prepare```
    - ```${COMPILE} make uImage -j 8```
    - ```${COMPILE} make dtbs -j 8```
    - ```${COMPILE} make modules -j 8```
6. install kernel and dtb to first partition of sdcard
    - ```cp arch/arm/boot/uImage /mnt/vfat/```
    - ```cp arch/arm/boot/dts/sun7i-a20-pcduino3.dtb /mnt/vfat/dtb```
7. install modules to the second partition
    - still inside the build directory
    - ```mkdir rootfs```
    - ```${COMPILE} make modules_install INSTALL_MOD_PATH=rootfs```
8. ```cd ~```

#### to rebuild the .config from scratch
1. generate the .config file and add the following to the kernel
    - ```ARCH=arm CROSS_COMPILER=arm-linux-gnueabihf- make sunxi_defconfig O=build```
    - ```ARCH=arm CROSS_COMPILER=arm-linux-gnueabihf- make menuconfig O=build```
    - select the following
        - ```bash
        [*] Enable loadable module support  —>
            [*] Forced module loading
            [*] Module unloading
            [*] Forced module unloading
        ```
        - ```bash
        System Type —>
        [*] Allwinner SoCs —>
            [*] Allwinner A20 (sun7i) SoCs support
        ```
        - ```bash
        [*] USB support —>
            <M> USB Mass Storage —>
            --- all as M
        ```
        - ```bash
        [*] Device Drivers ->
            [*] USB Serial Converter —>
                <M> USB Generic Serial Driver
                <M> USB FTDI
        ```
        - ```bash
        [*] Device Drivers ->
            [*] Network Device Support ->
                [*] Wireless Lan
            [*] Staging —>
                <M> RTL8188EU
                <M> as AP
        ```

### install rootfs
0. ensure the sdcard partitions are mounted (they should be from the previous steps)
    - ```sudo mount```
    - if not present, then
        - ```mkdir /mnt/vfat /mnt/ext4```
        - ```sudo mount -t vfat /dev/sdc1 /mnt/vfat```
        - ```sudo mount -t ext4 /dev/sdc2 /mnt/ext4```
1. ```sudo tar --strip-components=1 --show-transformed-names -C /mnt/ext4/ -zvxpf linaro-trusty-alip-20140821-681.tar.gz```

### install modules and firmware
1. ```cp -rfv linux-sunxi/rootfs/lib/ /mnt/ext4/lib/```
2. ```cp -rfv rtl8188eu/rtl8188eufw.bin /mnt/ext4/lib/firmware/```

### os setup

1. change wifi to be AP
    - to use wlan0 as a gateway, set wlan0 as static ip
        - edit /etc/network/interfaces
            ```bash
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
        ```bash
        sudo vim /etc/hostapd/hostapd.conf
        interface=wlan0
        ssid=gcs
        hw_mode=g
        channel=6
        auth_algs=1
        wmm_enabled=0
        ```
    - WHOA need to add the dnsmasq stuff

2. Turn on UART2 for GPS
    - add this to /etc/init/uart2.service
        ```bash
        echo “3″ > /sys/devices/virtual/misc/gpio/mode/gpio0
        echo “3″ > /sys/devices/virtual/misc/gpio/mode/gpio1
        ```
3. check that our 3dr radio is up
4. set hostname
    - ```sudo vim /etc/hostname```
        - gcs or gcs0001
    - ```sudo vim /etc/hosts```
        - same as above
5. configure avahi-daemon
    - ```sudo update-rc.d avahi-daemon defaults```
    - copy over afpd.service from dapper-hw
        - ```cp ~/dapper-hw/afpd.service /etc/avahi/services/afpd.service```
    - Restart Avahi: ```sudo /etc/init.d/avahi-daemon restart```
6. edit gpsd
    ```bash
    ubuntu@arm:~$ sudo dpkg-reconfigure gpsd
    ubuntu@arm:~$ cat /etc/default/gpsd

    # Default settings for gpsd.
    # Please do not edit this file directly - use `dpkg-reconfigure gpsd' to
    # change the options.
    START_DAEMON="true"
    GPSD_OPTIONS="-n -G"
    DEVICES="/dev/ttyO4"
    BAUDRATE="9600"
    USBAUTO="false"
    GPSD_SOCKET="/var/run/gpsd.sock"
    ```
7. reboot
    - ```sudo reboot```

### install gcs
1. nodejs symlink
    - ```sudo ln -s /usr/bin/nodejs /usr/bin/node```
2. GCS software prerequisites
    - ```sudo npm install -g grunt-cli bower forever nodemon```
3. copy over keys
    - ```scp ~/.ssh/github-keys* linaro@gcs:/home/linaro/.ssh/```
    - if no .ssh folder is on the gcs side
        - follow the guide from [github](https://help.github.com/articles/generating-ssh-keys)
        - or quickly generate a pair on the gcs then delete them
        - ```ssh-keygen -t rsa```
            - choose defaults, no password
        - ```rm .ssh/id_rsa*```
        - now scp the keys over
4. test that you can connect to github
    - ```ssh -T git@github.com```
4. clone repo
    ```git clone git@github.com:arctic-fire-development/dapper-gcs.git```
    ```bash
    cd dapper-gcs
    git submodule init
    git update
    npm install
    bower install
    grunt
    ```
- copy over the upstart script
    - ```sudo cp dapper-gcs.conf /etc/init/```
    - ```sudo start dapper-gcs```

references
- [clean build of uSD card]()
- [wifi ap mode](http://forum.odroid.com/viewtopic.php?f=52&t=1674)
- [usb otg to host](http://learn.linksprite.com/pcduino/usb-development/turn-usb-otg-port-into-an-extra-usb-host-pcduino3/)
- [pinouts](http://learn.linksprite.com/pcduino/arduino-ish-program/uart/how-to-directly-manupilate-uart-of-pcduino-under-linux/)
- [1. axp209 power management unit](http://learn.linksprite.com/pcduino/arduino-ish-program/adc/axp-209-internal-temperature/)
- [2. axp209 pmu kernel inclusion](https://github.com/linux-sunxi/linux-sunxi/commit/fcec507519157765c689ab3473a9e72d8b6df453)
- [external interrupts](http://pcduino.com/forum/index.php?topic=4727.0)
- [upstart script](http://unix.stackexchange.com/questions/84252/how-to-start-a-service-automatically-when-ubuntu-starts)
- [kernel build](http://www.crashcourse.ca/wiki/index.php/Building_kernel_out_of_tree)
