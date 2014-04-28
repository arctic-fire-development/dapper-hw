Dapper-HW
=========

Hardware related to the Ground Control Station


##Beagle Bone Black Installation

We are going to set this up to do everything from the sd card.

This will require:

    - flashing the eMMC to RobertCNelson's modified uBoot
    - installing ubuntu on the uSD card

1. Download the eMMC Flasher image
    - [14.04 eMMC Flasher](http://rcn-ee.net/deb/flasher/trusty/BBB-eMMC-flasher-ubuntu-14.04-2014-04-18-2gb.img.xz)
    - install to a micro SD card
    - insert micro SD card into unpowered BBB
    - hold the USER/BOOT button and apply power to BBB
        - LEDs will begin blinking
        - wait until all LEDs are stable
    - unpower BBB and remove micro SD card

2. Download the regular image
    - [14.04 uSD card image](http://rcn-ee.net/deb/microsd/trusty/bone-ubuntu-14.04-2014-04-18-2gb.img.xz)
    - install to a micro SD card
    - insert micro SD card into unpowered BBB
    - apply power to BBB (do NOT hold the USER/BOOT button)
        - LEDs will begin blinking

3. login to the BBB over usb
    - ```ssh ubuntu@192.168.7.2```
        - u: ubuntu
        - p: temppwd

4. configure ethernet
    - ```sudo nano /etc/network/interfaces```

        ```bash
        auto eth0
        allow-hotplug eth0
        iface eth0 inet static
        ```

5. set hostname
    - ```sudo nano /etc/hostname```
        - gcs or gcs0001

5. configure avahi-daemon
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

6. install packages
    - vim
        - ```sudo apt-get install vim```
    - nodejs and npm
        - ```sudo apt-get install nodejs npm```
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

6. set some preferences
    - ```vim .bashrc```
        - uncomment ```#force_color_prompt=yes```

