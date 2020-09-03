# z80usb

## Description

Z80 + usb + tinyfpga-bx

open source tools : Project ICESTORM (Yosys + NextPNR)

SDCC C-compiler
 
The default C program does a Silly ROT13 loop-back example.  putty <-> usb <-> z80
 
## Ingredients

* [iceZombie](https://github.com/abnoname/iceZ0mb1e)
  * [TV80](https://github.com/hutch31/tv80)
* [tinyfpga_bx_usbserial](https://github.com/davidthings/tinyfpga_bx_usbserial)
  * [tiny_usb_examples](https://github.com/lawrie/tiny_usb_examples)
    * [tinyfpga-bootloader](https://github.com/tinyfpga/TinyFPGA-Bootloader)

## Recipe

* make
* tinyprog -P z80usb.bin (with TinyFPGA-BX connected)
* Putty
  * Terminal -> Implicit LF in every CR
  * Serial -> COM8 (or whatever you commport is) -> Open
    * apio system --lsserial (show commport)
    
  
