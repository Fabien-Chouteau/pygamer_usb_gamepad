#!/bin/sh

arm-eabi-objcopy -O binary $(find . -name pygamer_usb_gamepad.elf) pygamer_usb_gamepad.bin

if ! test -f uf2conv.py; then
    wget https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2conv.py
    wget https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2families.json
fi

python2 uf2conv.py -b 16384 -c -o pygamer_usb_gamepad.uf2 pygamer_usb_gamepad.bin
