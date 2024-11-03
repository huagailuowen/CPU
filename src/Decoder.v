`include "Config.v"

module Decoder (
    input wire  clk_in,			// system clock signal
    input wire  rst_in,			// reset signal
	input wire  rdy_in,			// ready signal, pause cpu when low

    input wire [31:0] inst_in,	// instruction input
    input wire [31:0] inst,	    // instruction input
    input wire [31:0] inst_addr,// instruction address input
    output wire is_stall,		// stall signal


    // interaction with RF
    input wire [31:0]               rs1_val,
    input wire [31:0]               rs2_val,
    input wire                      rs1_has_dep,
    input wire                      rs2_has_dep,
    input wire [ROB_SIZE_BIT-1:0]   rs1_dep,
    input wire [ROB_SIZE_BIT-1:0]   rs2_dep,
    output wire [4:0]               rs1_id,
    output wire [4:0]               rs2_id,

    // interaction with ROB
    //FROM
    output wire [ROB_SIZE_BIT-1:0] rob_qry1_id,
    input wire                      rob_qry1_ready,
    input wire [31:0]              rob_qry1_value,
    output wire [ROB_SIZE_BIT-1:0]  rob_qry2_id,
    input wire                      rob_qry2_ready,
    input wire [31:0]              rob_qry2_value, 
    //TO
    input wire                      rob_full,		// ROB full signal
    input wire                      rob_id,			// the ROB id of the instruction
    output wire                     rob_input,      // the input signal of ROB
    output wire [31:0]              rob_value,      // in case that the ins is a lui etc.
    output wire [31:0]              rob_addr,       // the address of the instruction, for restarting ROB
    output wire [ROB_TYPE_BIT-1:0]  rob_type,       // the type of the instruction
    output wire [4:0]               rob_reg_id,     // the reg id of the instruction
    output wire                     rob_fi,         // is the instruction has finished, like lui



    // interaction with RS
    input wire                      rs_full,	    // RS full signal
    output wire                     rs_input,       // the input signal of RS
    output wire [31:0]              rs_r1_val,      
    output wire [31:0]              rs_r2_val,
    output wire                     rs_r1_has_dep,
    output wire                     rs_r2_has_dep,
    output wire [ROB_SIZE_BIT-1:0]  rs_r1_dep,
    output wire [ROB_SIZE_BIT-1:0]  rs_r2_dep,
    output wire [ROB_SIZE_BIT-1:0]  rs_rob_id,
    output wire [4:0]               rs_rd_id,


    // interaction with LSB
    input wire                      lsb_full,		// LSB full signal
    output wire                     lsb_input,      // the input signal of LSB
    output wire [31:0]              lsb_r1_val,      
    output wire [31:0]              lsb_r2_val,
    output wire                     lsb_r1_has_dep,
    output wire                     lsb_r2_has_dep,
    output wire [ROB_SIZE_BIT-1:0]  lsb_r1_dep,
    output wire [ROB_SIZE_BIT-1:0]  lsb_r2_dep,
    output wire [ROB_SIZE_BIT-1:0]  lsb_rob_id,
    output wire [4:0]               lsb_rd_id



);
//the instruction decoding this cycle is to be issued next cycle
/**
    1. decode
    2. query RF and ROB for information
    3. issue for the next cycle 
    */
