#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install bash-completetion vim nodejs npm build-essential python-dev python-setuptools python-pip python-smbus pv gpsd gpsd-clients ntp -y
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g grunt-cli bower forever nodemon
sudo rm -rf tmp
sudo pip install Adafruit_BBIO
sudo update-rc.d -f apache2 disable
