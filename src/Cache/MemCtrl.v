module MemCtrl(
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    // interaction with the outside
    input wire valid, // if need to work
    input wire is_write, // if write
    input wire [31:0] addr, // the address

    input wire [31:0] data_in, // the data, if write
    output wire [31:0] data_out, // the data
    output reg ready_out, // if the data is ready

    input wire [2:0] work_type;
    // first bit: signed or unsigned (0: unsigned, 1: signed)
    // second 2 bit : 00: byte, 01: half word, 10: word


    // interaction with the memory
    output wire mem_valid, // if need to work
    output wire mem_is_write, // if write
    output wire [31:0] mem_addr, // the address
    input wire [7:0] mem_data_in, // the data, if write
    output wire [7:0] mem_data_out, // the data

    
);

    reg [2:0] cur_work_type;
    reg cur_is_write;
    reg [31:0] cur_addr;
    reg [31:0] cur_data_in;
    reg [31:0] cur_data_out;
    // reg cur_ready_out;
    // ready_out is already a reg
    reg is_work;
    reg [1:0]cur_len;
    // how many bit has been read

always @(posedge clk_in)
begin
    if (rst_in)
    begin
        cur_work_type <= 0;
    end
else if (!rdy_in)
    begin
      
    end
else
    begin
      
    end
end

endmodule