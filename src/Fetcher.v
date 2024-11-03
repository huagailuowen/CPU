`include "Config.v"
module Fetcher(
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    // with Decoder
    input wire next_PC, // the next PC
    input wire is_stall, // stall signal

    output wire inst_ready_out, // if the instruction is ready
    output wire [31:0] inst_out, // the instruction
    output wire [31:0] inst_addr_out, // the address of the instruction

    // with InstCache
    output wire inst_req, // request signal
    output wire [31:0] inst_addr, // the address of the instruction
    input wire inst_ready_in, // if the instruction is ready
    input wire [31:0] inst, // the instruction

    input wire rob_clear, // if clear 
    input wire [31:0] rob_rst_addr, // the address of the instruction, for restarting ROB

);
    reg [31:0] PC;
endmodule