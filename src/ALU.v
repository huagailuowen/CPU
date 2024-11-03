`include "Config.v"
module ALU (
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    input wire                      alu_input,
    input wire [`RS_TYPE_BIT-1:0]   arith_type,
    input wire [31:0]               r1_val,
    input wire [31:0]               r2_val,
    input wire [`ROB_SIZE_BIT-1:0]  inst_rob_id,

    output reg                      alu_fi,
    output reg [31:0]               res
);
// our alu only need one cycle to finish the calculation



endmodule