`include "Config.v"
module RS(

    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    output wire rs_full,  // RS full signal

    // interaction with Decoder
    input wire inst_input,  // the input signal of Decoder
    input wire [`RS_TYPE_BIT-1:0] rs_type,  // the type of the instruction
    input wire [31:0] rs_r1_val,  // the value of rs1
    input wire [31:0] rs_r2_val,  // the value of rs2
    input wire rs_r1_has_dep,  // does rs1 has dependency
    input wire rs_r2_has_dep,  // does rs2 has dependency
    input wire [ROB_SIZE_BIT-1:0] rs_r1_dep,  // the ROB id of the dependency
    input wire [ROB_SIZE_BIT-1:0] rs_r2_dep,  // the ROB id of the dependency
    // input wire [31:0] rs_imm,  // the immediate value of the instruction
    input wire [ROB_SIZE_BIT-1:0] rs_rob_id, // the ROB id of the instruction
    // input wire [4:0] rs_rd_id,  // the rd id of the instruction

    // output to the cd_bus
    input wire rs_fi,
    input wire rs_value,
    input wire [ROB_SIZE_BIT-1:0] rs_rob_id,
    input wire lsb_fi,
    input wire lsb_value,
    input wire [ROB_SIZE_BIT-1:0] lsb_rob_id,
    // !!!!!WARNING!!!!!
    // these is alu's output, not rs's responsibility
    // replace by the alu 


    // interaction with ALU
    output wire alu_input,
    output wire [`RS_TYPE_BIT-1:0] arith_type,
    output wire [31:0] r1_val,
    output wire [31:0] r2_val,
    output wire [`ROB_SIZE_BIT-1:0] inst_rob_id
);
    localparam RS_SIZE_MAX = 6'b000100;
    reg [5:0] rs_size;
    assign rs_full = (rs_size == RS_SIZE_MAX) || (rs_size + 1 == RS_SIZE_MAX && inst_input && !merge_exe[0]);

    reg busy[0:`RS_SIZE-1];
    reg [31:0] r1_val[0:`RS_SIZE-1];
    reg [31:0] r2_val[0:`RS_SIZE-1];
    reg r1_has_dep[0:`RS_SIZE-1];
    reg r2_has_dep[0:`RS_SIZE-1];
    reg [ROB_SIZE_BIT-1:0] r1_dep[0:`RS_SIZE-1];
    reg [ROB_SIZE_BIT-1:0] r2_dep[0:`RS_SIZE-1];
    // reg [31:0] imm[0:`RS_SIZE-1];
    // do not need imm, alreay store in r2_val
    reg [RS_TYPE_BIT-1:0] type[0:`RS_SIZE-1];

    wire is_free[0:`RS_SIZE-1];
    wire [`RS_SIZE_BIT-1:0] free_id[0:`RS_SIZE-1];
    wire is_exe[0:`RS_SIZE-1];
    wire [`RS_SIZE_BIT-1:0] exe_id[0:`RS_SIZE-1];
    
    wire merge_free[0:`RS_SIZE-1];
    wire [`RS_SIZE_BIT-1:0] merge_free_id[0:`RS_SIZE-1];
    wire merge_exe[0:`RS_SIZE-1];
    wire [`RS_SIZE_BIT-1:0] merge_exe_id[0:`RS_SIZE-1];
    //use the design of tree array to find the free id and exe id

    wire tmp_rs_r1_has_dep = (rs_fi && rs_r1_has_dep && rs_rob_id == rs_r1_dep) ? 0 : ((lsb_fi && rs_r1_has_dep && lsb_rob_id == rs_r1_dep) ? 0 : rs_r1_has_dep);
    wire tmp_rs_r1_val = (rs_fi && rs_r1_has_dep && rs_rob_id == rs_r1_dep) ? rs_value : ((lsb_fi && rs_r1_has_dep && lsb_rob_id == rs_r1_dep) ? lsb_value : rs_r1_val);
    wire tmp_rs_r2_has_dep = (rs_fi && rs_r2_has_dep && rs_rob_id == rs_r2_dep) ? 0 : ((lsb_fi && rs_r2_has_dep && lsb_rob_id == rs_r2_dep) ? 0 : rs_r2_has_dep);
    wire tmp_rs_r2_val = (rs_fi && rs_r2_has_dep && rs_rob_id == rs_r2_dep) ? rs_value : ((lsb_fi && rs_r2_has_dep && lsb_rob_id == rs_r2_dep) ? lsb_value : rs_r2_val);    

    genvar i;
    generate
        for(i = 0; i < `RS_SIZE; i = i + 1)
        begin
            assign is_free[i] = ~busy[i];
            assign free_id[i] = i;
            assign is_exe[i] = busy[i] && !r1_has_dep[i] && !r2_has_dep[i];
            assign exe_id[i] = i;
        end
        for(i = 0; i < `RS_SIZE/2; i = i + 1)
        begin
            assign merge_free[i] = is_free[i<<1] && is_free[i<<1|1];
            assign merge_free_id[i] = is_free[i<<1] ? free_id[i<<1] : free_id[i<<1|1];
            assign merge_exe[i] = is_exe[i<<1] && is_exe[i<<1|1];
            assign merge_exe_id[i] = is_exe[i<<1] ? exe_id[i<<1] : exe_id[i<<1|1];
        end
    endgenerate
    assign alu_input = merge_exe[0];
    assign arith_type = type[merge_exe_id[0]];
    assign r1_val = r1_val[merge_exe_id[0]];
    assign r2_val = r2_val[merge_exe_id[0]];
    assign inst_rob_id = rs_rob_id[merge_exe_id[0]];
    integer i;
always @(posedge clk_in or posedge rst_in) 
begin
    if (rst_in || (rdy_in && rob_clear)) begin
        for(i = 0; i < `RS_SIZE; i = i + 1) begin
            busy[i] <= 0;
            r1_val[i] <= 0;
            r2_val[i] <= 0;
            r1_has_dep[i] <= 0;
            r2_has_dep[i] <= 0;  
            r1_dep[i] <= 0;
            r2_dep[i] <= 0;
            type[i] <= 0;
            rs_size <= 0;
        end
    end
    else if (rdy_in) 
    begin
        rs_size <= rs_size + merge_exe[0] - inst_input;
        if(inst_input) begin
            busy[merge_free_id[0]] <= 1;
            r1_val[merge_free_id[0]] <= tmp_rs_r1_val;
            r2_val[merge_free_id[0]] <= tmp_rs_r2_val;
            r1_has_dep[merge_free_id[0]] <= tmp_rs_r1_has_dep;
            r2_has_dep[merge_free_id[0]] <= tmp_rs_r2_has_dep;
            r1_dep[merge_free_id[0]] <= rs_r1_dep;
            r2_dep[merge_free_id[0]] <= rs_r2_dep;
            type[merge_free_id[0]] <= rs_type;
        end
        if(merge_exe[0]) begin
            busy[merge_exe_id[0]] <= 0;
        end
        for(i = 0; i < `RS_SIZE; i = i + 1) begin
            if(lsb_fi && r1_has_dep[i] && lsb_rob_id == r1_dep[i]) begin
                r1_val[i] <= lsb_value;
                r1_has_dep[i] <= 0;
            end
            if(lsb_fi && r2_has_dep[i] && lsb_rob_id == r2_dep[i]) begin
                r2_val[i] <= lsb_value;
                r2_has_dep[i] <= 0;
            end
            if(rs_fi && r1_has_dep[i] && rs_rob_id == r1_dep[i]) begin
                r1_val[i] <= rs_value;
                r1_has_dep[i] <= 0;
            end
            if(rs_fi && r2_has_dep[i] && rs_rob_id == r2_dep[i]) begin
                r2_val[i] <= rs_value;
                r2_has_dep[i] <= 0;
            end
        end
    end
end

endmodule