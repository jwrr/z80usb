##
## Makefile for z80usb
##

PROJTOP = z80usb

USB_DIR = ./submodules/tinyfpga_bx_usbserial
SOURCES = \
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

Z80_DIR = ./submodules/iceZ0mb1e
FIRMWARE_DIR = $(Z80_DIR)/firmware
FIRMWARE_IMG = iceZ0mb1e
CODE_LOCATION = 0x0200
DATA_LOCATION = 0x8000

SOURCES += $(Z80_DIR)/import/tv80/rtl/core/*.v
SOURCES += $(Z80_DIR)/import/tv80/rtl/uart/*.v
SOURCES += $(Z80_DIR)/rtl/*.v

SRC = pll.v $(Z80_DIR)/top/tinybx.v $(SOURCES)

PIN_DEF = $(Z80_DIR)/pinmap/tinybx.pcf

DEVICE = lp8k
PACKAGE = cm81

CLK_MHZ = 48
# CLK_MHZ = 16

all:  firmware $(PROJTOP).rpt $(PROJTOP).bin

.PHONY: firmware main
main:   
	cp submodules-mod/iceZ0mb1e/firmware/main/main.c.$(MAIN) submodules-mod/iceZ0mb1e/firmware/main/main.c
	ls submodules-mod/iceZ0mb1e/firmware/main/main.c*
	diff -s submodules-mod/iceZ0mb1e/firmware/main/main.c.$(MAIN) submodules-mod/iceZ0mb1e/firmware/main/main.c

firmware:
	make -C $(FIRMWARE_DIR) FIRMWARE_IMG=$(FIRMWARE_IMG) CODE_LOCATION=$(CODE_LOCATION) DATA_LOCATION=$(DATA_LOCATION)

pll.v:
	icepll -i 16 -o $(CLK_MHZ) -m -f pll.v

synth: $(PROJTOP).json

$(PROJTOP).json: $(SRC)
	yosys -q -f "verilog -D__def_fw_img=\"$(FIRMWARE_DIR)/$(FIRMWARE_IMG).vhex\"" -p 'synth_ice40 -top top  -json $@' $^

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) --freq $(CLK_MHZ) --opt-timing --timing-allow-fail --package $(PACKAGE) --pcf $(PIN_DEF) --json $*.json --asc $@

gui: $(PIN_DEF) $(PROJTOP).json
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --pcf $(PIN_DEF) --json $(PROJTOP).json --asc $(PROJTOP).asc --gui

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

prog: $(PROJTOP).bin
	tinyprog -p $<

init:
	cp -rv submodules-mod/*  submodules
	rm -f submodules/iceZ0mb1e/firmware/main/main_blinky.c

copy: # copy local files that have been changed
	cp -ruv submodules-mod/*  submodules

clean:
	make -C $(FIRMWARE_DIR) clean
	rm -f $(PROJTOP).json $(PROJTOP).asc $(PROJTOP).rpt $(PROJTOP).bin pll.v

.SECONDARY:
.PHONY: all synth prog clean gui
