//-----------------------------------------------------------------------------
// Block: simpletim
// Description: creates a timer that is readable from from processor
// This block has an free-running counter that increments each clock cycle.
// When processor writes to capture register the counters register is
// latched.  The process can the read the latched count.
//
// The timer is 32 bits. At 16MHz it rolls over at about 4.5 minutes.
//
//------------------------------------------------------------------------------
/*
   timer_cfg = 1;  // init
   while (1) {
       timer_wait 0,1,2,3;
       timer_cfg = 2; // start
       while (timer_busy);
   }
*/


module simpletimer (
    input         clk,
    input         reset_n,
    output  [7:0] data_out,
    input   [7:0] data_in,
    input         cs_n,
    input         rd_n,
    input         wr_n,
    input   [3:0] addr
);

    localparam TIMER_DEL0   = 0;
    localparam TIMER_DEL1   = 1;
    localparam TIMER_DEL2   = 2;
    localparam TIMER_DEL3   = 3;
    localparam TIMER_CFG    = 4;
    localparam TIMER_BUSY   = 5;
    localparam TIMER_NOW0   = 6;
    localparam TIMER_NOW1   = 7;
    localparam TIMER_NOW2   = 8;
    localparam TIMER_NOW3   = 9;

    reg         timer_busy;
    reg   [7:0] timer_cfg;
    reg  [31:0] timer_cnt;
    reg  [31:0] timer_now;
    reg  [31:0] timer_del;
    reg  [31:0] done_time;
    reg         start_pulse;
    reg         now_pulse;

    wire read_sel  = !cs_n & !rd_n &  wr_n;
    wire write_sel = !cs_n &  rd_n & !wr_n;

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            timer_cfg <= 8'h0;
            timer_del <= 32'h0;
            start_pulse <= 1'b0;
            now_pulse <= 1'b0;
        end else begin
            if (write_sel) begin
                case (addr)
                   TIMER_DEL0 : timer_del[0*8 +: 8] <= data_in;
                   TIMER_DEL1 : timer_del[1*8 +: 8] <= data_in;
                   TIMER_DEL2 : timer_del[2*8 +: 8] <= data_in;
                   TIMER_DEL3 : timer_del[3*8 +: 8] <= data_in;
                   TIMER_CFG  : timer_cfg <= data_in;
                endcase
            end
            start_pulse <= write_sel && addr==TIMER_CFG && data_in[1];
            now_pulse   <= write_sel && addr==TIMER_CFG && data_in[2];
        end
    end

    wire timer_on = timer_cfg[0];

    reg   [7:0] data_out;
    always@(*) begin
        if (~read_sel)
            data_out <= 8'b0;
        else begin
            case (addr)
                TIMER_DEL0 : data_out <= timer_del[0*8 +: 8];
                TIMER_DEL1 : data_out <= timer_del[1*8 +: 8];
                TIMER_DEL2 : data_out <= timer_del[2*8 +: 8];
                TIMER_DEL3 : data_out <= timer_del[3*8 +: 8];
                TIMER_CFG  : data_out <= timer_cfg;
                TIMER_BUSY : data_out <= {7'b0, timer_busy};
                TIMER_NOW0 : data_out <= timer_now[0*8 +: 8];
                TIMER_NOW1 : data_out <= timer_now[1*8 +: 8];
                TIMER_NOW2 : data_out <= timer_now[2*8 +: 8];
                TIMER_NOW3 : data_out <= timer_now[3*8 +: 8];
                default : data_out <= 8'b0;
            endcase
        end
    end


    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            timer_cnt  <= 32'h0;
            timer_now  <= 32'h0;
            done_time   <= 32'h0;
            timer_busy <= 1'b0;
        end else begin
            timer_cnt <= timer_on ? timer_cnt + 1 : 32'h0;

            if (now_pulse) timer_now <= timer_cnt;

            if (~timer_on) begin
                timer_busy <= 1'b0;
                done_time <= 'h0;
            end else if (start_pulse) begin
                timer_busy <= 1'b1;
                done_time <= done_time + timer_del;
            end else if (timer_busy && (timer_cnt == done_time) ) begin
                timer_busy <= 1'b0;
            end

        end // else if n
    end // always

endmodule






