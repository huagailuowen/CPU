module InstCache(
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low


    input wire [31:0] addr, 
    output wire is_hit,
    output wire [31:0] data_out.
    
    //update signal
    input wire is_update,
    input wire [31:0] data_in,
);
    localparam CACHE_SIZE_BIT = 8;
    localparam TAG_LEN = 32 - CACHE_SIZE_BIT;


    
endmodule