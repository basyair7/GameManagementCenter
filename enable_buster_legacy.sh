#!/bin/bash
# For RetroPie 4.8 (Debian Buster)
echo "Enabling Debian Buster Legacy Repository..."

echo "deb http://legacy.raspbian.org/raspbian/ buster main contrib non-free rpi" | sudo tee /etc/apt/sources.list
echo "deb http://legacy.raspberrypi.org/debian/ buster main" | sudo tee /etc/apt/sources.list.d/raspi.list

sudo apt update
echo "Done."
