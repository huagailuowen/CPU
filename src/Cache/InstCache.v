module InstCache(
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low


    input wire [31:0] addr, 
    output wire is_hit,
    output wire [31:0] data_out,
    
    //update signal
    input wire is_update,
    input wire [31:0] data_in,
    input wire [31:0] addr_in
);
    localparam CACHE_SIZE_BIT = 4;
    localparam TAG_LEN = 32 - CACHE_SIZE_BIT  - 2;
    reg [TAG_LEN-1:0] tag [0:(1<<CACHE_SIZE_BIT)-1];
    reg valid [0:(1<<CACHE_SIZE_BIT)-1];
    reg [31:0] data[0:(1<<CACHE_SIZE_BIT)-1];

    wire [CACHE_SIZE_BIT-1:0] cache_pos = addr_in[CACHE_SIZE_BIT+1:2];
    wire [CACHE_SIZE_BIT-1:0] updata_cache_pos = addr_in[CACHE_SIZE_BIT+1:2];
    assign is_hit = valid[cache_pos] && tag[cache_pos] == addr[31:CACHE_SIZE_BIT+2];
    assign data_out = data[cache_pos];

    // wire cache_pos_in = {{addr_in[CACHE_SIZE_BIT-1:1]} , 1'b0};
integer i;
always @(posedge clk_in)
begin
if (rst_in)
    begin
        for(i=0; i<(1<<CACHE_SIZE_BIT); i=i+1)begin
            tag[i] <= 0;
            valid[i] <= 0;
            data[i] <= 0;
        end
    end
else if(rdy_in)
    begin
        if(is_update)begin
            if(addr_in[1:0] != 2'b00)begin
                $display("Error: update addr_in[1:0] != 2'b00");
            end
            id(addr[1:0] != 2'b00)begin
                $display("Error: query addr[1:0] != 2'b00");
            end
            valid[updata_cache_pos] <= 1;
            tag[updata_cache_pos] <= addr_in[31:CACHE_SIZE_BIT+2];
            data[updata_cache_pos] <= data_in;
        end
    end    
end

endmodule