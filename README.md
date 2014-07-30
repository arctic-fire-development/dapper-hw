Dapper-HW
=========

Hardware related to the Ground Control Station


##Beagle Bone Black Installation

We are going to set this up to do everything from the sd card.

This will require:

    - flashing the eMMC to RobertCNelson's modified uBoot
    - installing ubuntu on the uSD card

1. Download the eMMC Flasher image
    - [BBB-eMMC-flasher-ubuntu-14.04-console-2014-06-05-2gb](http://rcn-ee.net/deb/flasher/trusty/BBB-eMMC-flasher-ubuntu-14.04-console-2014-06-05-2gb.img.xz)
    - install to a micro SD card
    - insert micro SD card into unpowered BBB
    - hold the USER/BOOT button and apply power to BBB
        - LEDs will begin blinking
        - wait until all LEDs are stable
    - unpower BBB and remove micro SD card

2. Download the regular uSD image
    - [bone-ubuntu-14.04-console-2014-06-05-2gb](http://rcn-ee.net/deb/microsd/trusty/bone-ubuntu-14.04-console-2014-06-05-2gb.img.xz)
    - install to a micro SD card
        - For OS X: [Pi Filler](http://ivanx.com/raspberrypi/)
    - insert micro SD card into unpowered BBB
    - apply power to BBB (do NOT hold the USER/BOOT button)
        - LEDs will begin blinking

3. login to the BBB over usb
    - ```ssh ubuntu@192.168.7.2```
        - u: ubuntu
        - p: temppwd

4. Expand the uSD file system
    ```bash
    $ sudo fdisk /dev/mmcblk0
    p
    d
    2
    n
    p
    2
    <enter>
    <enter>
    w
    $ sudo reboot

    # once the system is rebooted, ssh back in
    $ sudo resize2fs /dev/mmcblk0p2
    ```

5. configure ethernet
    - ```sudo nano /etc/network/interfaces```

        ```bash
        auto eth0
        allow-hotplug eth0
        iface eth0 inet dhcp
        ```

6. set hostname
    - ```sudo nano /etc/hostname```
        - gcs or gcs0001
    - ```sudo nano /etc/hosts```
        - same as above

7. configure avahi-daemon
    - ```sudo apt-get install avahi-daemon```
    - ```sudo update-rc.d avahi-daemon defaults```
    - Create a configuration file containing information about the server. Run “sudo nano /etc/avahi/services/afpd.service”. Enter (or copy/paste) the following

        ```xml
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
                <type>_afpovertcp._tcp</type>
                <port>548</port>
            </service>
            <service>
                <type>_device-info._tcp</type>
                <port>0</port>
                <txt-record>model=RackMac</txt-record>
            </service>
        </service-group>
        ```
    - Restart Avahi: ```sudo /etc/init.d/avahi-daemon restart```

8. install packages
    - bash autocompletion
        - ```sudo apt-get update && sudo apt-get install bash-completion```
    - vim
        - ```sudo apt-get install vim```
    - nodejs and npm
        - ```sudo apt-get install nodejs npm```
        - ```sudo ln -s /usr/bin/nodejs /usr/bin/node```
    - GCS software prerequisites
        - ```sudo npm install -g grunt-cli```
        - ```sudo npm install -g bower```
        - ```sudo npm install -g forever```
        - ```sudo npm install -g nodemon```
    - Adafruit BBB Python IO Library
        - ```sudo apt-get install build-essential python-dev python-setuptools python-pip python-smbus```
        - ```sudo pip install Adafruit_BBIO```
            - test that it works

                ```bash
                ubuntu@arm:~$ sudo python -c "import Adafruit_BBIO.GPIO as GPIO; print GPIO"

                you should see this or similar:
                <module 'Adafruit_BBIO.GPIO' from '/usr/local/lib/python2.7/dist-packages/Adafruit_BBIO/GPIO.so'>
                ```
9. Device Tree  (optional)
    - install dtc
        - ```wget -c https://raw.githubusercontent.com/RobertCNelson/tools/master/pkgs/dtc.sh```
        - ```chmod +x ./dtc.sh```
        - ```sudo ./dtc.sh```

        - verify installation

            ```bash
            ubuntu@arm:~$ which dtc
            /usr/local/bin/dtc
            ```
    - make a dts for the gps
        + ```cd /lib/firmware```
        + ```sudo wget -c https://raw.githubusercontent.com/arctic-fire-development/dapper-hw/master/T8LO-GPS-00A0.dts```
    - compile it using the dtc
        + ```sudo dtc -@ -I dts -O dtb -o T8LO-GPS-00A0.dtbo T8LO-GPS-00A0.dts```
    - ```sudo cp *.dtbo /lib/firmware/```
    - ```sudo sh -c "echo T8LO-GPS > /sys/devices/bone_capemgr.9/slots"```
    - ```cat /sys/devices/bone_capemgr.9/slots```

        ```bash
         0: 54:PF---
         1: 55:PF---
         2: 56:PF---
         3: 57:PF---
         4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
         5: ff:P-O-L Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI
        17: ff:P-O-L Override Board Name,00A0,Override Manuf,T8LO-GPS
        ```
10. install gpsd and ntp
    - ```sudo apt-get update && sudo apt-get install gpsd gpsd-clients ntp```

11. edit gpsd and ntp

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

    ```bash
    ubuntu@arm:~$ cat /etc/default/ntp
    NTPD_OPTS='-g'
    ```

12. add the following to the top of /etc/ntp.conf

    ```bash
    # /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help

    # NTP  GPS stuff

    # Read the rough GPS time from device 127.127.28.0
    # Read the accurate PPS time from device 127.127.22.0

    server 127.127.28.0 minpoll 4 maxpoll 4
    fudge 127.127.28.0 time1 0.535 refid GPS
    server 127.127.22.0 minpoll 4 maxpoll 4 prefer
    fudge 127.127.22.0 time1 0.000 flag3 1 refid PPS
    ```

13. edit /boot/uboot/uEnv.txt
    ```bash
    edit the optargs line, adding this line if required:

    optargs=capemgr.disable_partno=BB-BONELT-HDMI,BB-BONELT-HDMIN,BB-BONE-EMMC-2G capemgr.enable_partno=BB-UART4
    ```

14. verify gpsd is working
    - ```bash
    ubuntu@arm:~$ cgps
    ```
    - you should see a table output

15. verify ntp is working with pps
    - ```bash
    ubuntu@arm:~$ ntpq -p
    ```
    - if you don't see a pps entry, then we need to recompile ntp to use the ATOM driver

### Post Installation

1. set some preferences
    - ```vim .bashrc```
        - uncomment ```#force_color_prompt=yes```
    - ```vim .profile```
        - add the following:
            ```bash
            if ! shopt -oq posix; then
                if [ -f /etc/bash_completion.d/git-prompt ]; then
                    . /etc/bash_completion.d/git-prompt
                    export PS1='[\@] \[\033[0;32m\]\u@\h\[\033[00m\]:\[\033[0;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)")\$ '
                    export GIT_PS1_SHOWDIRTYSTATE=1
                    export GIT_PS1_SHOWSTASHSTATE=1
                    export GIT_PS1_SHOWUNTRACKEDFILES=1
                    export GIT_PS1_SHOWUPSTREAM="auto"
                fi
            fi
            ```
    - add your github public and private keys to ~/.ssh
    - test that you can connect to github
        - ```bash
        ubuntu@arm:~$ ssh -T git@github.com
        ```
        - or follow the guide from [github](https://help.github.com/articles/generating-ssh-keys)
    - clone the directory
        - ```bash
        ubuntu@arm:~$ git clone git@github.com:arctic-fire-development/dapper-gcs.git
        ```
        - ```bash
        cd dapper-gcs
        git submodule init
        git update
        npm install
        bower install
        grunt
        ```
2. clean up any ssh files
    - delete .ssh directory
    - delete .gitconfig

### Backup uSD card
We are going to load up a usb flash drive to the BBB, and then use dd and bzip2 to make a compressed image of the uSD card

1. bootup the BBB
2. insert the usb drive
3. ```sudo fdisk -l```
    ```output```
    notice the usb is located at /dev/sda1
    notice the uSD card is /dev/mmcblk0
4. from home directory
    ```mkdir usb0```
5. become root
    ```sudo su -```
6. mount the usb drive to the folder we just made
    ```
    mount -t vfat -o uid=ubuntu,gid=ubuntu /dev/sda1 /home/ubuntu/usb0
    exit
    ```
7. make the image
    ```sudo dd if=/dev/mmcblk0 | pv -s 2G -petr | bzip2 -9 > ./BBB-ubuntu-14.04-ArcticFireGCS.img.bz2```
8. remove the usb drive
    ```sudo umount /home/ubuntu/usb0```
9. profit

### Resources
    - [GPS integration](http://the8thlayerof.net/2013/12/08/adafruit-ultimate-gps-cape-creating-custom-beaglebone-black-device-tree-overlay-file/)

### Troubleshooting

#### OS X doesn't recognize the BBB in network interfaces anymore

##### First go around

    ```
    Today i started configuring my beaglebone board. While the first time after installing the USB driver and the tethering HoRNDIS driver, it soon stopped working. I ended up getting multiple entries in my network configuration.

    This will fix the issue:

    Edit these two files and remove all entries containing beagleboard (beginning with <key>, including the following <dict> entry until </dict>). Do  this for every key/dict pair that holds a “Beagle” propery/string. – After removing all these from the two .plist files, i rebooted, and it was immediately working again! if i would have known this, i would have saved lots of time reinstalling the drivers again and again … ;-)

    /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist

    /Library/Preferences/SystemConfiguration/preferences.plist
    ```

[Source](http://blog.b-nm.at/2014/02/12/beagleboard-beaglebone-no-connection-via-usbnetwork-anymore-on-osx-10-9-mavericks/)

##### Second go around

    ```
    I have solved this problem by resetting the SMC and the PRAM. Here are the details if someone needs it:

    Reset the SMC and PRAM
    - SMC Reset:
        - Shut down the MacBook Pro.
        - Plug in the MagSafe power adapter to a power source, connecting it to the Mac if its not already connected.
        - On the built-in keyboard, press the (left side) Shift-Control-Option keys and the power button at the same time.
        - Release all the keys and the power button at the same time.
        - Press the power button to turn on the computer.
    - PRAM:
        - Shut down the MacBook Pro.
        - Locate the following keys on the keyboard: Command, Option, P, and R.
        - Turn on the computer.
        - Press and hold the Command-Option-P-R keys. You must press this key combination before the gray screen appears.
        - Hold the keys down until the computer restarts and you hear the startup sound for the second time.
        - Release the keys.
    - After following the above two steps I plugged in the beaglebone and it was detected in the network interface. I was then able to successfully ssh into it.
    ```

[Source](http://stackoverflow.com/questions/23318071/beagle-bone-black-not-detected-in-network-interface-on-mac)
