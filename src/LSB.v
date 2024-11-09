`include "Config.v"
module LSB(

    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    output wire lsb_full,  // lsb full signal

    // interaction with Decoder
    input wire write_back,  // write back signal
    input wire inst_input,  // the input signal of Decoder
    input wire [`LSB_TYPE_BIT-1:0] lsb_type,  // the type of the instruction
    //[1:is_write] [3:func3]

    input wire [31:0] lsb_r1_val,  // the value of lsb1
    input wire [31:0] lsb_r2_val,  // the value of lsb2
    input wire lsb_r1_has_dep,  // does lsb1 has dependency
    input wire lsb_r2_has_dep,  // does lsb2 has dependency
    input wire [ROB_SIZE_BIT-1:0] lsb_r1_dep,  // the ROB id of the dependency
    input wire [ROB_SIZE_BIT-1:0] lsb_r2_dep,  // the ROB id of the dependency
    input wire [31:0] lsb_imm,  // the immediate value of the instruction
    input wire [ROB_SIZE_BIT-1:0] lsb_rob_id, // the ROB id of the instruction
    // input wire [4:0] lsb_rd_id,  // the rd id of the instruction


    // output to the cd_bus
    output wire lsb_fi,
    output wire lsb_value,
    output wire [ROB_SIZE_BIT-1:0] lsb_rob_id,

    // interaction with Cache

);

    reg busy[0:`LSB_SIZE-1];
    reg [31:0] r1_val[0:`LSB_SIZE-1];
    reg [31:0] r2_val[0:`LSB_SIZE-1];
    reg r1_has_dep[0:`LSB_SIZE-1];
    reg r2_has_dep[0:`LSB_SIZE-1];
    reg [`ROB_SIZE_BIT-1:0] r1_dep[0:`LSB_SIZE-1];
    reg [`ROB_SIZE_BIT-1:0] r2_dep[0:`LSB_SIZE-1];
    reg [`LSB_TYPE_BIT-1:0] type[0:`LSB_SIZE-1];
    reg [31:0] imm[0:`RS_SIZE-1];
    reg [`LSB_SIZE_BIT-1:0] head, tail;


always @(posedge clk_in or posedge rst_in) 
begin
    if (rst_in) begin
        
    end
    else if (rdy_in) 
    begin
        
    end
end
endmodule