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

module simpleusb_wrapper (
    input        clk,
    input        rst_n,
    input        cs_n,
    input        rd_n,
    input        wr_n,
    input  [1:0] addr,
    input  [7:0] data_in,
    output [7:0] data_out,

    input        clk_48mhz,
    input        rst_48mhz,
    output       pin_usb_pu,
    inout        pin_usb_p,
    inout        pin_usb_n,

    output [11:0] debug

);
    localparam GEN_USB = 1;

    localparam  STAT  = 2'h0;
    localparam  RECV  = 2'h1;
    localparam  SEND  = 2'h2;

    assign       pin_usb_pu = 1'b1;

    wire         read_sel = !cs_n & !rd_n & wr_n;
    wire         write_sel = !cs_n & rd_n & !wr_n;

    reg    [7:0] read_data;
    wire         uart_out_valid;

    reg  [1:0]   rx_valid_cdc;
    always @(posedge clk) rx_valid_cdc <= {rx_valid_cdc[0], uart_out_valid};
    wire         rx_valid = rx_valid_cdc[1];
    
    reg          rx_valid2;
    always @(posedge clk) begin
        rx_valid2 <= rx_valid;
        if (rx_valid & ~rx_valid2) begin // rising edge
           debug = ~debug;
        end
    end
        


    reg  [1:0]     tx_ready_cdc;
    wire           uart_in_ready;
    always @(posedge clk) tx_ready_cdc <= {tx_ready_cdc[0], uart_in_ready};
    wire          tx_ready = tx_ready_cdc[1];


    wire         tx_ready;
    wire   [7:0] reg_status = {6'b0, tx_ready, rx_valid};
    reg    [7:0] rx_data;
    always @(*)
    begin
        case (addr)
            STAT : read_data = reg_status;
            RECV : read_data = rx_data;
            default : read_data = 8'h00;
        endcase
    end
    assign data_out = read_sel ? read_data : 8'b0;


    wire read_stat1 = read_sel && addr==STAT;
    reg  read_stat2;
    always @(posedge clk)
    begin
        read_stat2 <= read_stat1;
    end
    wire read_stat_pulse = !read_stat1 & read_stat2;  // trailing edge


    reg read_rx1;
    always @(posedge clk) read_rx1 <= read_sel && addr==RECV;
    reg  [2:0] read_rx_cdc;
    reg        read_rx_pulse;
    wire [7:0] uart_out_data;
    reg  [7:0] rx_data;
    always @(posedge clk_48mhz)
    begin
        read_rx_cdc <= {read_rx_cdc[1:0], read_rx1};
        read_rx_pulse <= read_rx_cdc[2:1] == 2'b10; // trailing edge
        if (uart_out_valid) rx_data <= uart_out_data;
    end


    wire        write_tx1 = write_sel && addr==SEND;
    reg  [2:0]  write_tx_cdc;
    reg         write_tx_pulse;
    reg         uart_out_valid2;
    always @(posedge clk_48mhz)
    begin
        write_tx_cdc <= {write_tx_cdc[1:0], write_tx1};
        if (write_tx_cdc[2:1] == 2'b01)
           write_tx_pulse <= 1'b1;
        else if (uart_in_ready) begin
           write_tx_pulse <= 1'b0;
        end
    end


    reg [7:0] tx_data;
    always @(posedge clk) begin
        if (write_tx1) tx_data <= data_in;
    end

    wire loopback = 1'b1;
//     wire [7:0] uart_in_data   = loopback ? uart_out_data  : tx_data;
//     wire       uart_in_valid  = loopback ? uart_out_valid : write_tx_pulse;
//    wire       uart_out_ready = loopback ? uart_in_ready  : read_rx_pulse;
    wire [7:0] uart_in_data   = tx_data;
    wire       uart_in_valid  = write_tx_pulse;
    wire       uart_out_ready = read_rx_pulse;

    reg [9:0] fake_cnt;


    generate
    if (GEN_USB==1) begin
    usb_uart uart (
        .clk_48mhz      (clk_48mhz),       // input
        .reset          (rst_48mhz),       // input
        .pin_usb_p      (pin_usb_p),       // inout
        .pin_usb_n      (pin_usb_n),       // inout

        .uart_out_data  (uart_out_data),   // output [7:0]
        .uart_out_valid (uart_out_valid),  // output rx fifo not empty (status)
        .uart_out_ready (uart_out_ready),  // input  read from host (rx fifo)

        .uart_in_data   (uart_in_data),    // input  [7:0]
        .uart_in_valid  (uart_in_valid),   // input  write to host (tx fifo)
        .uart_in_ready  (uart_in_ready),   // output tx fifo not full (status)

// FIXME         .debug          (debug)            // output [11:0]
    );
    end
    else begin

       always @(posedge clk)
       begin
           if (~rst_n) begin
               fake_cnt <= 'h0;
           end
           else begin
               if (read_stat_pulse) fake_cnt <= fake_cnt + 1;
           end
       end

       assign uart_out_valid = fake_cnt[0];
       assign tx_ready = fake_cnt[1];
       assign uart_out_data  = fake_cnt[9:2];
    end
    endgenerate

    


endmodule
