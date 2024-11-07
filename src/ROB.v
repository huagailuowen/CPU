`include "Config.v"

module ROB (

    input wire clk_in, // system clock signal
    input wire rst_in, // reset signal
    input wire rdy_in, // ready signal, pause cpu when low

    

    output wire rob_full, // ROB full signal
    output wire [ROB_SIZE_BIT-1:0]rob_free_id, // the ROB id of the next instruction
    output wire rob_clear, // clear the ROB
    output wire rob_rst_addr, // the address of the instruction, for restarting ROB

    // interaction with Decoder
    //FROM
    input wire rob_input, // the input signal of ROB
    input wire [31:0] rob_value, // in case that the ins is a lui etc.
    input wire [31:0] rob_addr, // the address of the instruction, for restarting ROB
    input wire [ROB_TYPE_BIT-1:0] rob_type, // the type of the instruction
    input wire [4:0] rob_reg_id, // the reg id of the instruction
    input wire rob_fi, // is the instruction has finished, like lui

    //TO
    input wire [ROB_SIZE_BIT-1:0] rob_qry1_id, // the ROB id of the instruction
    output wire rob_qry1_ready, // if the instruction has been finished
    output wire [31:0] rob_qry1_value, // the value of the instruction, if finished
    input wire [ROB_SIZE_BIT-1:0] rob_qry2_id, // the ROB id of the instruction
    output wire rob_qry2_ready, // if the instruction has been finished
    output wire [31:0] rob_qry2_value, // the value of the instruction, if finished



    // interaction with RS
    input wire rs_fi, // the output signal of RS
    input wire [31:0] rs_value, // the output value of RS
    // input wire [4:0] rs_rd_id, // the rd id of the instruction
    input wire [ROB_SIZE_BIT-1:0] rs_rob_id, // the ROB id of the instruction

    // interaction with LSB
    output wire write_back,     // write back signal

    input wire lsb_fi, // the output signal of LSB
    input wire [31:0] lsb_value, // the output value of LSB
    // input wire [4:0] lsb_rd_id, // the rd id of the instruction
    input wire [ROB_SIZE_BIT-1:0] lsb_rob_id // the ROB id of the instruction


);
    reg [ROB_SIZE_BIT-1:0] head;
    reg [ROB_SIZE_BIT-1:0] tail;
    reg [31:0] res[ROB_SIZE_BIT-1:0];
    reg [31:0] inst_addr[ROB_SIZE_BIT-1:0];
    // reg [4:0] rd_id[ROB_SIZE_BIT-1:0];
    reg [ROB_TYPE_BIT-1:0] type[ROB_SZIE_BIT-1:0];

always @(posedge clk_in or posedge rst_in) 
begin
    if (rst_in) begin
        
    end
    else if (rdy_in) 
    begin

    end
end

endmodule