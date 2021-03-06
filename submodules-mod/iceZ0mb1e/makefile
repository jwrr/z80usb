#
# iceZ0mb1e - FPGA 8-Bit TV80 SoC for Lattice iCE40
# with complete open-source toolchain flow using yosys and SDCC
#
# Copyright (c) 2018 Franz Neumann (netinside2000@gmx.de)
#
# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the "Software"), 
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included 
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#


###############################################################################
# USB
###############################################################################
USB_DIR = tinyfpga_bx_usbserial
SRC = \
	$(USB_DIR)/usb/edge_detect.v \
	$(USB_DIR)/usb/serial.v \
	$(USB_DIR)/usb/usb_fs_in_arb.v \
	$(USB_DIR)/usb/usb_fs_in_pe.v \
	$(USB_DIR)/usb/usb_fs_out_arb.v \
	$(USB_DIR)/usb/usb_fs_out_pe.v \
	$(USB_DIR)/usb/usb_fs_pe.v \
	$(USB_DIR)/usb/usb_fs_rx.v \
	$(USB_DIR)/usb/usb_fs_tx_mux.v \
	$(USB_DIR)/usb/usb_fs_tx.v \
	$(USB_DIR)/usb/usb_reset_det.v \
	$(USB_DIR)/usb/usb_serial_ctrl_ep.v \
	$(USB_DIR)/usb/usb_uart_bridge_ep.v \
	$(USB_DIR)/usb/usb_uart_core.v \
	$(USB_DIR)/usb/usb_uart_i40.v


###############################################################################
# Hardware
###############################################################################
SRC += ./import/tv80/rtl/core/*.v
SRC += ./import/tv80/rtl/uart/*.v
SRC += ./rtl/*.v
TESTBENCH = ./tb/tb_iceZ0mb1e.v
GTKW_FILE = ./tb/tb_iceZ0mb1e.gtkw

###############################################################################
# Software
###############################################################################
FIRMWARE_DIR = ./firmware
FIRMWARE_IMG = iceZ0mb1e
CODE_LOCATION = 0x0200
DATA_LOCATION = 0x8000

###############################################################################
# IO
###############################################################################
SERIALPORT = /dev/ttyUSB1
SERIALBAUD = 9600

###############################################################################
# Default
###############################################################################
TARGET = 5k

ifeq ($(TARGET),1k)
	SRC += ./top/hx1k.v
	ARACHNEFLAGS = -d 1k
	FPGA_PINMAP = ./pinmap/hx1k.pcf
#	NEXTPNRFLAGS = --hx1k --package tq144 --pcf $(FPGA_PINMAP) --freq 12 --opt-timing --json $(FPGA_JSON) --asc $(FPGA_ASC)
else ifeq ($(TARGET),icezum)
	SRC += ./top/icezum.v
	ARACHNEFLAGS = -d 1k
	FPGA_PINMAP = ./pinmap/icezum.pcf
#	NEXTPNRFLAGS = --hx1k --package tq144 --pcf $(FPGA_PINMAP) --freq 12 --opt-timing --json $(FPGA_JSON) --asc $(FPGA_ASC)
else ifeq ($(TARGET),5k)
	SRC += ./top/upduino.v
	ARACHNEFLAGS = -d 5k -P sg48
	ICETIMEFLAGS = -d up5k -P sg48
	FPGA_PINMAP = ./pinmap/upduino.pcf
	ICEPROG_PARAM = -d i:0x0403:0x6014
#	NEXTPNRFLAGS = --up5k --package sg48 --pcf $(FPGA_PINMAP) --freq 12 --opt-timing --json $(FPGA_JSON) --asc $(FPGA_ASC)
else ifeq ($(TARGET),8k)
	SRC += ./top/hx8k.v
	ARACHNEFLAGS = -d 8k -P ct256
	FPGA_PINMAP = ./pinmap/hx8k.pcf
#	NEXTPNRFLAGS = --hx8k --package ct256 --pcf $(FPGA_PINMAP) --freq 12 --opt-timing --json $(FPGA_JSON) --asc $(FPGA_ASC)
else ifeq ($(TARGET),tinybx)
	SRC += ./top/tinybx.v
	ARACHNEFLAGS = -d 8k -P cm81
	FPGA_PINMAP = ./pinmap/tinybx.pcf
	NEXTPNRFLAGS = --lp8k --package cm81 --pcf $(FPGA_PINMAP) --freq 48 --timing-allow-fail --opt-timing --json $(FPGA_JSON) --asc $(FPGA_ASC)

else
endif

###############################################################################
# Tool Output
###############################################################################
SIM_DIR = ./simulation
SYNTH_DIR = ./synthesis
VCD_OUT = $(SIM_DIR)/_test.vcd
COMPILE_OUT = $(SIM_DIR)/_compiler.out
SYNTH_OUT = $(SYNTH_DIR)/_synth_output.v
FPGA_BLIF_OUT = $(SYNTH_DIR)/_fpga.blif
FPGA_TXT_OUT = $(SYNTH_DIR)/_fpga.txt
FPGA_EX_OUT = $(SYNTH_DIR)/_fpga.ex
FPGA_BIN_OUT = $(SYNTH_DIR)/_fpga.bin
FPGA_JSON = $(SYNTH_DIR)/_fpga.json
FPGA_ASC = $(SYNTH_DIR)/_fpga.asc
FPGA_TIM_OUT = $(SYNTH_DIR)/_fpga_tim.rpt

###############################################################################
# Tools
###############################################################################
COMPILER = iverilog
SIMULATOR = vvp
VIEWER = gtkwave
YOSYS = yosys
ARACHNEPNR = arachne-pnr
NEXTPNR = nextpnr-ice40
ICEBOXEXPLAIN = icebox_explain
ICEPACK = icepack
ICEPROG = sudo iceprog
ICETIME = icetime
QFLOW = qflow

WSLENV ?= notwsl
ifndef WSLENV
    # this runs when you _are_ in WSL
    ICEPROG = iceprog.exe
endif

#Tool Options
YOSYSFLAGS = -f "verilog -D__def_fw_img=\"$(FIRMWARE_DIR)/$(FIRMWARE_IMG).vhex\"" -p "synth_ice40 -blif $(FPGA_BLIF_OUT);"
YOSYSFLAGS_NEXTPNR = -q -f 'verilog -D__def_fw_img="$(FIRMWARE_DIR)/$(FIRMWARE_IMG).vhex"' -p 'synth_ice40 -top top -json $(FPGA_JSON)'
COFLAGS = -s tb_iceZ0mb1e -D__def_fw_img=\"$(FIRMWARE_DIR)/$(FIRMWARE_IMG).vhex\" -D__def_vcd_file=\"$(VCD_OUT)\"
SFLAGS = -v
SOUTPUT = -lxt

###############################################################################
# Firmware
###############################################################################
.PHONY: firmware
firmware:
	$(MAKE) -C $(FIRMWARE_DIR) FIRMWARE_IMG=$(FIRMWARE_IMG) CODE_LOCATION=$(CODE_LOCATION) DATA_LOCATION=$(DATA_LOCATION)

###############################################################################
# Simulation
###############################################################################
$(COMPILE_OUT): $(TESTBENCH)
	-mkdir $(SIM_DIR)
	$(COMPILER) $(COFLAGS) -o $(COMPILE_OUT) $(TESTBENCH) $(SRC)

$(VCD_OUT): $(COMPILE_OUT)
	$(SIMULATOR) $(SFLAGS) $(COMPILE_OUT) $(SOUTPUT)

sim: firmware $(COMPILE_OUT) $(VCD_OUT)
	$(VIEWER) -g -a $(GTKW_FILE) $(VCD_OUT)

###############################################################################
# Synthesis
###############################################################################
fpga: rtl/pll.v $(SRC) $(FPGA_PINMAP) firmware
	-mkdir $(SYNTH_DIR)
	$(YOSYS) -q -o $(SYNTH_OUT) $(YOSYSFLAGS) $(SRC)
	$(ARACHNEPNR) $(ARACHNEFLAGS) -p $(FPGA_PINMAP) $(FPGA_BLIF_OUT) -o $(FPGA_TXT_OUT)
	$(ICEBOXEXPLAIN) $(FPGA_TXT_OUT) > $(FPGA_EX_OUT)
	$(ICEPACK) $(FPGA_TXT_OUT) $(FPGA_BIN_OUT)
	
rtl/pll.v:
	icepll -i 16 -o 48 -m -f rtl/pll.v

time:
	$(ICETIME) -mt -p $(FPGA_PINMAP) $(ICETIMEFLAGS) $(FPGA_TXT_OUT)

flash: $(FPGA_BIN_OUT)
	$(ICEPROG) $(ICEPROG_PARAM) $(FPGA_BIN_OUT)

sram: $(FPGA_BIN_OUT)
	$(ICEPROG) -S $(ICEPROG_PARAM) $(FPGA_BIN_OUT)


###############################################################################
# Synthesis using nextpnr
# 'nextpnr' runs yosys, nextpnr, icepack and icetime
###############################################################################
nextpnr: $(FPGA_TIM_OUT)

$(FPGA_JSON): firmware $(SRC)
	-mkdir $(SYNTH_DIR)
	$(YOSYS) $(YOSYSFLAGS_NEXTPNR) $(SRC)

$(FPGA_ASC): $(FPGA_PINMAP) $(FPGA_JSON)
	$(NEXTPNR) $(NEXTPNRFLAGS)

$(FPGA_BIN_OUT): $(FPGA_ASC)
	$(ICEPACK) $(FPGA_ASC) $(FPGA_BIN_OUT)

$(FPGA_TIM_OUT): $(FPGA_BIN_OUT)
	$(ICETIME) -mtr $(FPGA_TIM_OUT) $(FPGA_ASC)


###############################################################################
serial:
	#stty raw -F $(SERIALPORT) speed $(SERIALBAUD)
	#gtkterm --port $(SERIALPORT) --speed $(SERIALBAUD)
	echo "To end the session, press Ctrl+a followed by k."
	screen $(SERIALPORT) $(SERIALBAUD)

clean:
	$(MAKE) -C $(FIRMWARE_DIR) clean
	rm -f $(SYNTH_OUT)
	rm -f $(SIM_DIR)/*
	rm -f $(SYNTH_DIR)/*
