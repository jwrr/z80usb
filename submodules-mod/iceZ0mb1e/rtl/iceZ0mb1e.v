//
// iceZ0mb1e - FPGA 8-Bit TV80 SoC for Lattice iCE40
// with complete open-source toolchain flow using yosys and SDCC
//
// Copyright (c) 2018 Franz Neumann (netinside2000@gmx.de)
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

module iceZ0mb1e  #(
	parameter RAM_TYPE = 0,
	parameter RAM_WIDTH = 12, // reduce from 8K to 4KByte (saves 8 EBRAM)
	parameter ROM_WIDTH = 13,
	parameter RAM_LOC = 16'h8000,
	parameter GEN_USB = 0,
        parameter GEN_PLL = 0
) (
	input  clk,
	input  rst,
	output uart_txd,
	input  uart_rxd,
	output i2c_scl,
	input  i2c_sda_in,
	output i2c_sda_out,
	output i2c_sda_oen,
	output spi_sclk,
	output spi_mosi,
	input  spi_miso,
 	output spi_cs,
 	output [7:0] P1_out,
 	input  [7:0] P1_in,
	output P1_oen,
	output [7:0] P2_out,
	input  [7:0] P2_in,
	output P2_oen,
	inout  USBP,
	inout  USBN,
	output USBPU,
	output [11:0] usb_dbg
);
	localparam ROM_SIZE = (1 << ROM_WIDTH);
	localparam RAM_SIZE = (1 << RAM_WIDTH);

	//Z80 Bus:
	wire        reset_n;
	reg         wait_n = 1'b0;
	reg         int_n = 1'b0;
	reg         nmi_n = 1'b0;
	reg         busrq_n = 1'b0;
	wire        m1_n;
	wire        mreq_n;
	wire        iorq_n;
	wire        rd_n;
	wire        wr_n;
	wire        rfsh_n;
	wire        halt_n;
	wire        busak_n;
	wire [15:0] addr;
	wire [7:0]  data_miso;
	wire [7:0]  data_mosi;

        wire [7:0] data_miso_rom;
        wire [7:0] data_miso_ram;
        wire [7:0] data_miso_port;
        wire [7:0] data_miso_uart;
        wire [7:0] data_miso_i2c;
        wire [7:0] data_miso_spi;
        wire [7:0] data_miso_timer;
        wire [7:0] data_miso_usb;
        assign data_miso = data_miso_rom   | data_miso_ram  | data_miso_port |
                           data_miso_uart  | data_miso_i2c  | data_miso_spi  |
                           data_miso_timer | data_miso_usb;


	//Reset Controller:
	always @(posedge clk) begin
		if( reset_n == 1'b0 ) begin
			wait_n	<= 1'b1;
			int_n	<= 1'b1;
			nmi_n	<= 1'b1;
			busrq_n	<= 1'b1;
		end
	end

	wire uart_cs_n, port_cs_n, i2c_cs_n, spi_cs_n, timer_cs_n, usb_cs_n;
	wire rom_cs_n, ram_cs_n;

	//I/O Address Decoder:
	assign uart_cs_n  = ~(!iorq_n & (addr[7:3] == 5'b00011)); // UART base 0x18
	assign port_cs_n  = ~(!iorq_n & (addr[7:3] == 5'b01000)); // PORT base 0x40
	assign i2c_cs_n   = ~(!iorq_n & (addr[7:3] == 5'b01010)); // i2c base 0x50
	assign spi_cs_n   = ~(!iorq_n & (addr[7:3] == 5'b01100)); // spi base 0x60 01100 000 -> 0110 0000
	assign timer_cs_n = ~(!iorq_n & (addr[7:3] == 5'b01110)); // spi base 0x70 01110 000 -> 0111 0000
	assign usb_cs_n   = ~(!iorq_n & (addr[7:3] == 5'b10000)); // spi base 0x80 10000 000 -> 1000 0000
	//Memory Address Decoder:
	assign rom_cs_n = ~(!mreq_n & (addr  < ROM_SIZE));
	assign ram_cs_n = ~(!mreq_n & (addr >= RAM_LOC) & (addr < (RAM_LOC+RAM_SIZE)));

        wire ram_cs_n_bad = ~(!mreq_n & (addr >= (RAM_LOC+RAM_SIZE)));

	//SoC Info
	initial begin
		$display("iceZ0mb1e Configuration Info" );
		$display("ROM width = %d, size = %X", ROM_WIDTH, ROM_SIZE );
		$display("RAM width = %d, size = %X", RAM_WIDTH, RAM_SIZE );
		$display("RAM type = %d", RAM_TYPE );
	end

	tv80s cpu
	(
		.m1_n		(m1_n),
		.mreq_n		(mreq_n),
		.iorq_n		(iorq_n),
		.rd_n		(rd_n),
		.wr_n		(wr_n),
		.rfsh_n		(rfsh_n),
		.halt_n		(halt_n),
		.busak_n	(busak_n),
		.A		(addr[15:0]),
		.data_out	(data_mosi),
		.reset_n	(reset_n),
		.clk		(clk),
		.wait_n		(wait_n),
		.int_n		(int_n),
		.nmi_n		(nmi_n),
		.busrq_n	(busrq_n),
		.data_in	(data_miso)
	);
	defparam cpu.Mode = 0; // 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
	defparam cpu.T2Write = 1; // 0 => wr_n active in T3, /=0 => wr_n active in T2
	defparam cpu.IOWait = 1; // 0 => Single cycle I/O, 1 => Std I/O cycle

	membram #(ROM_WIDTH, `__def_fw_img, 1) rom
	(
    	.clk		(clk),
    	.reset_n	(reset_n),
    	.data_out	(data_miso_rom),
    	.data_in	(8'h0),
    	.cs_n		(rom_cs_n),
    	.rd_n		(rd_n),
    	.wr_n		(wr_n),
    	.addr		(addr[ROM_WIDTH-1:0])
	);

generate
    if(RAM_TYPE == 1) begin
		//UltraPlus SPRAM
		memspram #(RAM_WIDTH) ram
		(
			.clk		(clk),
			.reset_n	(reset_n),
			.data_out	(data_miso_ram),
			.data_in	(data_mosi),
			.cs_n		(ram_cs_n),
			.rd_n		(rd_n),
			.wr_n		(wr_n),
			.addr		(addr[RAM_WIDTH-1:0])
		);
	end else if(RAM_TYPE == 2) begin
		//ext. SRAM => todo
		//
    end else begin
		//FPGA BRAM
		membram #(RAM_WIDTH)  ram
		(
			.clk		(clk),
			.reset_n	(reset_n),
			.data_out	(data_miso_ram),
			.data_in	(data_mosi),
			.cs_n		(ram_cs_n),
			.rd_n		(rd_n),
			.wr_n		(wr_n),
			.addr		(addr[RAM_WIDTH-1:0])
		);
	end
endgenerate

	simpleio ioporta
	(
		.clk		(clk),
		.reset_n	(reset_n),
		.data_out	(data_miso_port),
		.data_in	(data_mosi),
		.cs_n		(port_cs_n),
		.rd_n		(rd_n),
		.wr_n		(wr_n),
		.addr		(addr[1:0]),
		.P1_out		(P1_out),
		.P1_in		(P1_in),
		.P1_oen		(P1_oen),
		.P2_out		(P2_out),
		.P2_in		(P2_in),
		.P2_oen		(P2_oen)
	);

	uart16540_wrapper uart0
	(
		.clk		(clk),
		.reset_n	(reset_n),
		.data_out	(data_miso_uart),
		.data_in	(data_mosi),
		.cs_n		(uart_cs_n),
		.rd_n		(rd_n),
		.wr_n		(wr_n),
		.addr		(addr[2:0]),
		.rx			(uart_rxd),
		.tx			(uart_txd)
	);

	simplei2c_wrapper i2c0 (
		.clk		(clk),
		.reset_n	(reset_n),
		.data_out	(data_miso_i2c),
		.data_in	(data_mosi),
		.cs_n		(i2c_cs_n),
		.rd_n		(rd_n),
		.wr_n		(wr_n),
		.addr		(addr[2:0]),
		.i2c_sda_in		(i2c_sda_in),
		.i2c_sda_out	(i2c_sda_out),
		.i2c_sda_oen	(i2c_sda_oen),
		.i2c_scl_out	(i2c_scl)
	);

	simplespi_wrapper spi0 (
		.clk		(clk),
		.reset_n	(reset_n),
		.data_out	(data_miso_spi),
		.data_in	(data_mosi),
		.cs_n		(spi_cs_n),
		.rd_n		(rd_n),
		.wr_n		(wr_n),
		.addr		(addr[2:0]),
		.sclk		(spi_sclk),
		.mosi		(spi_mosi),
		.miso		(spi_miso),
		.cs			(spi_cs)
	);

	simpletimer timer0
	(
		.clk		(clk),
		.reset_n	(reset_n),
		.data_out	(data_miso_timer),
		.data_in	(data_mosi),
		.cs_n		(timer_cs_n),
		.rd_n		(rd_n),
		.wr_n		(wr_n),
		.addr		(addr[3:0])
	);

        // ===============================================================
        // ===============================================================

    wire clk_48mhz;
    wire clk_locked;
    

    generate
       if (GEN_PLL) begin
          pll pll48( .clock_in(clk), .clock_out(clk_48mhz), .locked(clk_locked) );
       end
       else begin
          assign clk_48mhz = clk;
          assign clk_locked = 1'b1;
       end 
    endgenerate
    
    // Generate reset signal
    reg [5:0] reset_cnt;
    always @(posedge clk) begin
       if (~clk_locked)
          reset_cnt <= 6'h1;
       else begin
          if (reset_cnt != 0) reset_cnt <= reset_cnt + 1;
       end
    end
    wire      reset1  = reset_cnt != 0;
    wire      reset   = rst | reset1;
    assign    reset_n = ~reset;

    generate
       if (GEN_USB) begin
          simpleusb_wrapper usb0 (
             .clk        (clk),
             .rst_n      (reset_n),
             .clk_48mhz  (clk_48mhz),
             .rst_48mhz  (reset),
      
             .pin_usb_p  (USBP),
             .pin_usb_n  (USBN),
             .pin_usb_pu (USBPU),
      
             .cs_n       (usb_cs_n),
             .rd_n       (rd_n),
             .wr_n       (wr_n),
             .addr       (addr[1:0]),
             .data_in    (data_mosi),
             .data_out   (data_miso_usb),
      
             .debug      (usb_dbg)
          );
       end
       else begin
          assign USBPU = 1;
          assign data_miso_usb = 8'b0;
          assign usb_dbg = 12'b0;
       end
    endgenerate

endmodule

