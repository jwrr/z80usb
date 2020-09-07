# z80usb

## Description

tinyfpga-bx + usb + z80 + morse code

This project combines a USB core with the 8-bit Z80 processor on the TinyFPGA-
BX. C code running on the Z80 generates Morse Code that blinks on the LED.
When the board starts up it blinks a default message on the LED.  When you
type into the terminal, your message blinks on the LED.  Your message is
also echo'ed back to the terminal display.  If you don't type for a while, the 
default message starts to blink again.

The [TinyFPGA-BX](https://www.crowdsupply.com/tinyfpga/tinyfpga-ax-bx) is a small
circuit board with a Lattice ICE40LP8K FPGA, a USB interface, many IO and one LED.

The ICE40LP8K can, of course, be programmed with proprietary Lattice Tools. But
what's really interesting is that it can also be programmed using the open
tool-chain from [Project IceStorm](http://www.clifford.at/icestorm/),
including the [Yosys Synthesis Suite](http://www.clifford.at/yosys/), and the
[NextPNR Place and Route Tool](https://github.com/YosysHQ/nextpnr). Given the
secretive nature of FPGA vendors, I was sceptical of an open tool chain, but
I've used it for a while and find it very stable and produces good results.
Congratulations to the team. I look forward to trying
[Project X-Ray](https://symbiflow.github.io/getting-started.html) on an
[Arty-7](https://store.digilentinc.com/arty-a7-artix-7-fpga-development-board-for-makers-and-hobbyists/).

The ICE40LP8K has 7680 Look-Up Tables (LUTs), 32 4Kbit Embedded Block
memories (EBRAMs) and a PLL. It's not huge but it's enough to do quite a few
low-cost projects.

Most boards with a USB interface use a FTDI (or clone) chip to handle the USB protocol.
The TinyFPGA-BX has FPGA code that handles the
[USB interface](https://github.com/davidthings/tinyfpga_bx_usbserial).
This approach uses FPGA resources but it allows for a simpler,lower-cost board
design.

I've become re-interested in the classic [Heathkit H89](https://sebhc.github.io/sebhc/).
My dad built a couple in the late 1970s. It had a [Zilog Z80 processor](http://www.z80.info/).
The [TV80](https://github.com/hutch31/tv80) is a verilog implementaton of the
Z80.  It can be programmed using the open-source
[Small Device C Compiler](https://sourceforge.net/projects/sdcc/).  The
[iceZ0mb1e](https://github.com/abnoname/iceZ0mb1e) provides a good starting
point, instantiating the TV80 with several usefule IO blocks and memory.

## License

This project is licensed under the [Apache 2 License](https://www.apache.org/licenses/LICENSE-2.0),
which is the permissive license used by the USB core. IceZ0mbie and my source
files are licensed under the even-more-permissive [MIT License](https://opensource.org/licenses/MIT).

Some of my change have been PR'ed upstream to the iceZ0mb1e project.  But I'm not
sure if the Apache-licensed USB-core can integrated into the MIT-Licensed
Icez0mb1e. I'm no license expert, but my feeble understanding is that MIT can
be merged into Apache, but Apache can't be merged into MIT (please correct me
if I'm wrong).


## Repos Used by the Project

* [iceZombie](https://github.com/abnoname/iceZ0mb1e)
  * [TV80](https://github.com/hutch31/tv80)
* [tinyfpga_bx_usbserial](https://github.com/davidthings/tinyfpga_bx_usbserial)
  * [tiny_usb_examples](https://github.com/lawrie/tiny_usb_examples)
    * [tinyfpga-bootloader](https://github.com/tinyfpga/TinyFPGA-Bootloader)


## Download and Install

These steps clone the repo and download the submodules (most of the work is in 
the submodules).

git clone https://github.com/jwrr/z80usb
cd z80usb
git submodule update --init


## Build Instructions

make clean; make main MAIN=morse; make


## Program the FPGA

* tinyprog -p z80usb.bin (with TinyFPGA-BX connected)


## Terminal Program

* Putty
  * Terminal -> Implicit LF in every CR
  * Serial -> COM8 (or whatever you commport is) -> Open
    * apio system --lsserial (show commport)


