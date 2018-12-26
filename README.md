Please see master branch for original u-boot README (and licence).

----

# Intro

This is u-boot for `winas` hardware. 

`winas` is based on Rockchip RK3328 platform, with a spi nor flash as the booting device and a sata drive, connected to USB port via a JMicron JMS578 bridge ic, as the main storage for rootfs and user data.

The u-boot expects a `boot.scr` on the first primary partition. 
- By u-boot convention, either `/boot.scr` or `/boot/boot.scr` works. 
- The primary partition must be formatted as ext4 file system. 
- Only ms-dos partition table is supported.

# Usage

## Generating SPI image file

```
./build.sh
```

This script generates the spi image. There are two identical output files: `idbloader.img` and `rksd_loader.img`. The latter is named after the ayufan's spi flash image.

## Flash SPI image

No dedicated tool is provided. Use ayufan's spi flash tool instead.

Download ayufan's spi flash image from ayufan's u-boot release for rock64.

https://github.com/ayufan-rock64/linux-u-boot/releases

The filename is `u-boot-flash-spi-rock64.img.xz`.

Flash the image to SD card. I use `Etcher` personally. `dd` should work too.

Replace the `rksd_loader.img` with custom built file.

Insert the SD card to `winas` hardware and power up the system.

Example output:

```
DDR version 1.13 20180428
ID:0x805 N
In
DDR3
786MHz
Bus Width=32 Col=10 Bank=8 Row=15/15 CS=2 Die Bus-Width=16 Size=2048MB
ddrconfig:6
OUT

U-Boot SPL 2017.09-rockchip-ayufan-1035-gd646df03ac (Oct 26 2018 - 08:35:43)
setup_ddr_param  1
booted from SD
Trying to boot from MMC2
NOTICE:  BL31: v1.3(debug):9d3f591
NOTICE:  BL31: Built : 14:39:02, Jan 17 2018
NOTICE:  BL31:Rockchip release version: v1.3
INFO:    ARM GICv2 driver initialized
INFO:    Using opteed sec cpu_context!
INFO:    boot cpu mask: 1
INFO:    plat_rockchip_pmu_init: pd status 0xe
INFO:    BL31: Initializing runtime services
WARNING: No OPTEE provided by BL2 boot loader, Booting device without OPTEE initialization. SMC`s destined for OPTEE will return SMC_UNK
ERROR:   Error initializing runtime service opteed_fast
INFO:    BL31: Preparing for EL3 exit to normal world
INFO:    Entry point address = 0x200000
INFO:    SPSR = 0x3c9


U-Boot 2017.09-rockchip-ayufan-1035-gd646df03ac (Oct 26 2018 - 08:36:01 +0000)

Model: Pine64 Rock64
DRAM:  2 GiB
MMC:   rksdmmc@ff520000: 0, rksdmmc@ff500000: 1
SF: Detected w25q64cv with page size 256 Bytes, erase size 4 KiB, total 8 MiB
*** Warning - bad CRC, using default environment

In:    serial@ff130000
Out:   serial@ff130000
Err:   serial@ff130000
Model: Pine64 Rock64
misc_init_r
cpuid=55524b50303930343400000000111c1e
serial=3a9716feead44b5
Net:   eth0: ethernet@ff540000
Hit any key to stop autoboot:  0 
Card did not respond to voltage select!
mmc_init: -95, time 10
switch to partitions #0, OK
mmc1 is current device
Scanning mmc 1:2...
Found U-Boot script /boot.scr
reading /boot.scr
832 bytes read in 2 ms (406.3 KiB/s)
## Executing script at 00500000
SF: Detected w25q64cv with page size 256 Bytes, erase size 4 KiB, total 8 MiB
reading rksd_loader.img
807652 bytes read in 38 ms (20.3 MiB/s)
SF: 4161536 bytes @ 0x8000 Erased: OK
device 0 offset 0x8000, size 0xc52e4
SF: 807652 bytes @ 0x8000 Written: OK
```

At the end, remove the SD card and reboot the system.

A successful boot log looks like:

```
DDR version 1.12 20180104
In
DDR3
786MHz
Bus Width=32 Col=10 Bank=8 Row=15/15 CS=2 Die Bus-Width=16 Size=2048MB
ddrconfig:6
OUT

U-Boot SPL 2017.09-g84a033efd5-dirty (Dec 25 2018 - 22:44:40)
setup_ddr_param  1
booted from SPI flash
Trying to boot from SPI
NOTICE:  BL31: v1.3(debug):9d3f591
NOTICE:  BL31: Built : 14:39:02, Jan 17 2018
NOTICE:  BL31:Rockchip release version: v1.3
INFO:    ARM GICv2 driver initialized
INFO:    Using opteed sec cpu_context!
INFO:    boot cpu mask: 1
INFO:    plat_rockchip_pmu_init: pd status 0xe
INFO:    BL31: Initializing runtime services
WARNING: No OPTEE provided by BL2 boot loader, Booting device without OPTEE initialization. SMC`s destined for OPTEE will return SMC_UNK
ERROR:   Error initializing runtime service opteed_fast
INFO:    BL31: Preparing for EL3 exit to normal world
INFO:    Entry point address = 0x200000
INFO:    SPSR = 0x3c9


U-Boot 2017.09-g84a033efd5-dirty (Dec 25 2018 - 22:44:43 +0800)

DRAM:  2 GiB
MMC:   rksdmmc@ff500000: 1
SF: Detected w25q64cv with page size 256 Bytes, erase size 64 KiB, total 8 MiB
*** Warning - bad CRC, using default environment

In:    serial@ff130000
Out:   serial@ff130000
Err:   serial@ff130000
Model: Pine64 Rock64
misc_init_r
Hit any key to stop autoboot:  0 
starting USB...
USB0:   Register 2000140 NbrPorts 2
Starting the controller
USB XHCI 1.10
scanning bus 0 for devices... cannot reset port 1!?
2 USB Device(s) found
       scanning usb for storage devices... 1 Storage Device(s) found

Device 0: Vendor: JMicron  Rev: 0210 Prod: Tech            
            Type: Hard Disk
            Capacity: 1907729.0 MB = 1863.0 GB (3907029168 x 512)
... is now current device
Scanning usb 0:1...
Found U-Boot script /boot/boot.scr
142 bytes read in 123 ms (1000 Bytes/s)
## Executing script at 00500000
hello world!
devtype usb
devnum 0
SCRIPT FAILED: continuing...
MMC Device 0 not found
no mmc device at slot 0
=> 
```

In this log, JMicron bridge is probed and `/boot/boot.scr` is loaded and executed.

There is chance that the usb device probe fails. The log looks like:

```
U-Boot 2017.09-g84a033efd5-dirty (Dec 25 2018 - 22:44:43 +0800)

DRAM:  2 GiB
MMC:   rksdmmc@ff500000: 1
SF: Detected w25q64cv with page size 256 Bytes, erase size 64 KiB, total 8 MiB
*** Warning - bad CRC, using default environment

In:    serial@ff130000
Out:   serial@ff130000
Err:   serial@ff130000
Model: Pine64 Rock64
misc_init_r
normal boot
Hit any key to stop autoboot:  0 
starting USB...
USB0:   Register 2000140 NbrPorts 2
Starting the controller
USB XHCI 1.10
scanning bus 0 for devices... cannot reset port 1!?
Device NOT ready
   Request Sense returned 04 44 81
2 USB Device(s) found
       scanning usb for storage devices... 1 Storage Device(s) found

Device 0: Vendor: JMicron  Rev: 0210 Prod: Tech            
            Type: Hard Disk
            Capacity: not available
... is now current device
WARN halted endpoint, queueing URB anyway.
Unexpected XHCI event TRB, skipping... (7df85630 00000000 13000000 01008401)
"Synchronous Abort" handler, esr 0x96000210
ELR:     7ffb7114
LR:      7ffb7114
x0 : 0000000000000000 x1 : 00000000000003e8
x2 : 0000000000000040 x3 : 000000000000003f
x4 : 000000007df85ed0 x5 : 0000000000000031
x6 : 000000007ffcde56 x7 : 00000000ffffffe8
x8 : 000000007df77be0 x9 : 0000000000000008
x10: 00000000000000ff x11: 0000000000000021
x12: 0000000000000080 x13: 00000000000032e8
x14: 000000007df78a8c x15: 0000000000000008
x16: 0000000000000000 x17: 0000000000000000
x18: 000000007df80e08 x19: 000000007df843c0
x20: 000000007df90810 x21: 0000000000000000
x22: 000000007df89e10 x23: 0000000000000000
x24: 0000000000000000 x25: 0000000080000203
x26: 0000000000000001 x27: 0000000000000001
x28: 000000007df77f00 x29: 000000007df77d60

Resetting CPU ...
```

`Unexpected XHCI event` will trigger a reset. If there is no sata driver, or the capacity is not retrieved, this error occurs. This won't be fixed in near future. If the device drops into a dead loop, the only way to clear the problem is a power cycle.











