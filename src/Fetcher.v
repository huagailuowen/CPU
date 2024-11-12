`include "Config.v"
module Fetcher(
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    // with Decoder
    input wire next_PC, // the next PC, valid when is_stall is low
    input wire is_stall, // stall signal

    output wire inst_ready_out, // if the instruction is ready
    output wire [31:0] inst_out, // the instruction
    output wire [31:0] inst_addr_out, // the address of the instruction

    // with InstCache
    output wire inst_req, // request signal
    output wire [31:0] inst_addr, // the address of the next instruction
    input wire inst_handle, // if the instruction is handled
    input wire inst_ready_in, // if the instruction is ready
    input wire [31:0] inst_in, // the instruction

    // with ROB
    input wire rob_clear, // if clear 
    input wire [31:0] rob_rst_addr // the address of the instruction, for restarting ROB

);
    reg [31:0] PC;
    reg [31:0] inst;
    reg ready;
    reg fetching;
    
    wire tmp_PC = rob_clear ? rob_rst_addr : (is_stall ? PC : next_PC);
    wire tmp_ready = inst_ready_in ? 1 : ((rob_clear || !is_stall) ? 0 : ready);   
    //can cache response in one cycle? maybe it can
    wire tmp_fetching = inst_handle ? 1 : ((rob_clear || !is_stall)? 0 : fetching);
    wire tmp_inst = inst_handle ? inst_in : inst;
    assign inst_req = (rob_clear || !is_stall) ? 1 : !fetching;
    assign inst_addr = tmp_PC;



    // assign inst_ready_out = tmp_ready;
    // assign inst_out = tmp_inst;
    // assign inst_addr_out = tmp_PC;
    // can't do this because of the timing problem, inst_out should be stable 
    assign inst_ready_out = (rob_clear) ? 0 : ready;
    assign inst_out = inst;
    assign inst_addr_out = PC;

always @(posedge clk_in)
begin
    if (rst_in) begin
        PC <= 0;
        ready <= 0;
        fetching <= 0;
    end
    else if (rdy_in) begin
        fetching <= tmp_fetching;
        ready <= tmp_ready;
        PC <= tmp_PC;
        inst <= tmp_inst;
        
        if (rob_clear) begin
        
        end
        else if (!is_stall) begin
        
        end 
        else begin
        end
    end

end
endmodule