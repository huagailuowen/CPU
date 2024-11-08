`include "Config.v"

module Cache(
    // the memory write back operation should not be influence by the rob_clear signal
    //!!!!!!!!! WARNING !!!!!!!!! 
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    input wire need_inst, // if need instruction
    input wire [31:0] inst_addr,
    output wire inst_ready, // if the instruction is ready
    output wire [31:0] inst_out, // the instruction

    input wire need_data, // if need data
    input wire is_write, // if write
    input wire [31:0] data_addr,
    input wire [2:0] work_type, 
    // first bit: signed or unsigned (0: unsigned, 1: signed)
    // second 2 bit : 00: byte, 01: half word, 10: word
    
    output wire data_ready, // if the data is ready
    output wire [31:0] data_out, // the data
    
    //the data is with priority ?
);

endmodule