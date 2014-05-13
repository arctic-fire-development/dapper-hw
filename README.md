Dapper-HW
=========

Hardware related to the Ground Control Station


##Beagle Bone Black Installation

We are going to set this up to do everything from the sd card.

This will require:

    - flashing the eMMC to RobertCNelson's modified uBoot
    - installing ubuntu on the uSD card

1. Download the eMMC Flasher image
    - [BBB-eMMC-flasher-ubuntu-14.04-2014-05-06-2gb](http://rcn-ee.net/deb/flasher/trusty/BBB-eMMC-flasher-ubuntu-14.04-2014-05-06-2gb.img.xz)
    - install to a micro SD card
    - insert micro SD card into unpowered BBB
    - hold the USER/BOOT button and apply power to BBB
        - LEDs will begin blinking
        - wait until all LEDs are stable
    - unpower BBB and remove micro SD card

2. Download the regular uSD image
    - [bone-ubuntu-14.04-2014-05-06-2gb](http://rcn-ee.net/deb/microsd/trusty/bone-ubuntu-14.04-2014-05-06-2gb.img.xz)
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
    - vim
        - ```sudo apt-get install vim```
    - nodejs and npm
        - ```sudo apt-get install nodejs npm```
        - ```sudo ln -s /usr/bin/nodejs /usr/bin/node```
    - GCS software prerequisites
        - ```sudo npm install -g grunt-cli```
        - ```sudo npm install -g nodemon```
    - Adafruit BBB Python IO Library
        - ```sudo apt-get install build-essential python-dev python-setuptools python-pip python-smbus```
        - ```sudo pip install Adafruit_BBIO```
            - test that it works

                ```bash
                sudo python -c "import Adafruit_BBIO.GPIO as GPIO; print GPIO"

                you should see this or similar:
                <module 'Adafruit_BBIO.GPIO' from '/usr/local/lib/python2.7/dist-packages/Adafruit_BBIO/GPIO.so'>
                ```


### Post Installation

1. set some preferences
    - ```vim .bashrc```
        - uncomment ```#force_color_prompt=yes```
2. clean up any ssh files
    - delete .ssh directory
    - delete .gitconfig


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

