#!/bin/bash

# Restore a "cnmbook" or similar AK7802 laptop with Windows CE.

if [ ! -f "PRODUCER.nb0" ]; then echo "Missing PRODUCER.nb0 file."; exit 1; fi
if [ ! -f "nboot_ddr_V5.0.bin" ]; then echo "Missing nboot_ddr_V5.0.bin file."; exit 1; fi
if [ ! -f "eboot.nb0" ]; then echo "Missing eboot.nb0 file."; exit 1; fi
if [ ! -f "xip.nb0" ]; then echo "Missing xip.nb0 file."; exit 1; fi

xargs ./ak78tool <<EOF

$(: Initialize DRAM)
set 0x080000dc 0x00000000
set 0x08000004 0x0000d000
sleep 1
set 0x66668888 0x000000c8
set 0x08000064 0x08000000
set 0x080000a8 0x04000000
set 0x2002d004 0x0f506b15
set 0x66668888 0x000000c8
set 0x2002d000 0x40170000
set 0x2002d000 0x40120400
set 0x66668888 0x00000001
set 0x2002d000 0x40104000
set 0x66668888 0x00000001
set 0x2002d000 0x40100123
set 0x66668888 0x00000001
set 0x2002d000 0x40120400
set 0x66668888 0x00000001
set 0x2002d000 0x40110000
set 0x66668888 0x00000001
set 0x2002d000 0x40110000
set 0x66668888 0x00000001
set 0x2002d000 0x40100023
set 0x66668888 0x00000001
set 0x2002d000 0x60170000
set 0x2002d008 0x00057c58

$(: Put the producer shim into DRAM and run it)
download 0x30038000 PRODUCER.nb0
go 0x30038000

$(: Wait for the producer to come up)
waitreset
ping

$(: Not sure why this is necessary)
ptread 364 /dev/null

$(: Erase all)
erase 2

$(: Flash the SPL image into partition 0)
write 0 nboot_ddr_V5.0.bin

$(: Flash the bootloader image into partition 1)
write 1 eboot.nb0

$(: Flash the Windows CE image)
ce 4 xip.nb0

$(: Ensure the NAND flash writes finish)
sync
EOF
