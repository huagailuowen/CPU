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
    output reg [`ROB_SIZE_BIT-1:0]  cur_rob_id,
    output reg [31:0]               res
);
// our alu only need one cycle to finish the calculation
    //[1:is_branch] [3:func3] [1:func7]
    
    localparam ADD = 4'b0000;
    localparam SUB = 4'b0001;
    localparam AND = 4'b1110;
    localparam OR  = 4'b1100;
    localparam XOR = 4'b1000;
    localparam SLL = 4'b0010;
    localparam SRL = 4'b1010;
    localparam SRA = 4'b1011;
    localparam SLT = 4'b0100;
    localparam SLTU= 4'b0110; 

    localparam BEQ = 3'b000;
    localparam BNE = 3'b001;
    localparam BLT = 3'b100;
    localparam BGE = 3'b101;
    localparam BLTU= 3'b110;
    localparam BGEU= 3'b111;

always @(posedge clk_in or posedge rst_in) 
begin
    if (rst_in) begin
        alu_fi <= 0;
        cur_rob_id <= 0;
        res <= 0;
    end
    else if (rdy_in) 
    begin
        alu_fi <= alu_input;
        if(alu_input)
            cur_rob_id <= inst_rob_id;
        else
            cur_rob_id <= 0;
        end
        if (arith_type[4])
        begin 
            case(arith_type[3:1]) 
                BEQ: res <= r1_val == r2_val;
                BGE: res <= $signed(r1_val) >= $signed(r2_val);
                BGEU: res <= r1_val >= r2_val;
                BLT: res <= r1_val < r2_val;
                BLTU: res <= $signed(r1_val) < $signed(r2_val);
                BNE: res <= r1_val != r2_val;
            endcase
        end
        else
        begin
            case(arith_type[3:0])
                ADD: res <= r1_val + r2_val;
                SUB: res <= r1_val - r2_val;
                AND: res <= r1_val & r2_val;
                OR: res <= r1_val | r2_val;
                XOR: res <= r1_val ^ r2_val;
                SLL: res <= r1_val << r2_val[4:0];
                SRL: res <= r1_val >> r2_val[4:0];
                SRA: res <= $signed(r1_val) >>> r2_val[4:0];
                SLT: res <= $signed(r1_val) < $signed(r2_val);
                SLTU: res <= r1_val < r2_val;
            endcase

        end
    end
end


endmodule