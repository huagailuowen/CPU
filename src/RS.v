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

    reg busy[0:`RS_SIZE-1];
    reg [31:0] r1_val[0:`RS_SIZE-1];
    reg [31:0] r2_val[0:`RS_SIZE-1];
    reg r1_has_dep[0:`RS_SIZE-1];
    reg r2_has_dep[0:`RS_SIZE-1];
    reg [ROB_SIZE_BIT-1:0] r1_dep[0:`RS_SIZE-1];
    reg [ROB_SIZE_BIT-1:0] r2_dep[0:`RS_SIZE-1];
    reg [RS_TYPE_BIT-1:0] type[0:`RS_SIZE-1];

    wire is_free[0:`RS_SIZE-1];
    wire [`RS_SIZE_BIT-1:0] free_id[0:`RS_SIZE-1];
    wire is_exe[0:`RS_SIZE-1];
    wire [`RS_SIZE_BIT-1:0] exe_id[0:`RS_SIZE-1];
    //use the design of tree array to find the free id and exe id

