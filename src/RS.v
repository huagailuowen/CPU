`include "Config.v"
module RS(

    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    output wire rs_full,  // RS full signal

    // interaction with Decoder
    input wire inst_input,  // the input signal of Decoder
    input wire [31:0] rs_r1_val,  // the value of rs1
    input wire [31:0] rs_r2_val,  // the value of rs2
    input wire rs_r1_has_dep,  // does rs1 has dependency
    input wire rs_r2_has_dep,  // does rs2 has dependency
    input wire [ROB_SIZE_BIT-1:0] rs_r1_dep,  // the ROB id of the dependency
    input wire [ROB_SIZE_BIT-1:0] rs_r2_dep,  // the ROB id of the dependency
    input wire [ROB_SIZE_BIT-1:0] rs_rob_id, // the ROB id of the instruction
    // input wire [4:0] rs_rd_id,  // the rd id of the instruction

    // output to the cd_bus
    output wire rs_fi,
    output wire rs_value,
    output wire [ROB_SIZE_BIT-1:0] rs_rob_id,

);
