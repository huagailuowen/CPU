`include "Config.v"
module RF(
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    // interaction with ROB
    input wire rob_clear, // clear the ROB
    input wire is_update_val_in,
    input wire [4:0]update_val_id,
    input wire [`ROB_SIZE_BIT-1:0] update_val_dep,
    input wire [31:0] update_val,

    input wire is_update_dep_in,
    input wire [4:0]update_dep_id,
    input wire [`ROB_SIZE_BIT-1:0] update_dep,

    // interaction with Decoder
    // input wire is_qry_r1,
    // input wire is_qry_r2,
    input wire [4:0] qry_r1_id,
    input wire [4:0] qry_r2_id,
    output wire [31:0] qry_r1_val,
    output wire [31:0] qry_r2_val,
    output wire [`ROB_SIZE_BIT-1:0] qry_r1_dep,
    output wire [`ROB_SIZE_BIT-1:0] qry_r2_dep,
    output wire qry_r1_has_dep,
    output wire qry_r2_has_dep

);
    wire is_update_val = update_val_id == 0 ? 0 : is_update_val_in;
    wire is_update_dep = update_dep_id == 0 ? 0 : is_update_dep_in;
    //handle the zero register
    reg [31:0] reg_val[0:31];
    reg [`ROB_SIZE_BIT-1:0] reg_dep[0:31];
    reg has_dep[0:31];

    // wire [31:0] zero = reg_val[0];
    // wire [31:0] ra = reg_val[1];
    // wire [31:0] sp = reg_val[2];
    // wire [31:0] gp = reg_val[3];
    // wire [31:0] tp = reg_val[4];
    // wire [31:0] t0 = reg_val[5];
    // wire [31:0] t1 = reg_val[6];
    // wire [31:0] t2 = reg_val[7];
    // wire [31:0] s0 = reg_val[8];
    // wire [31:0] s1 = reg_val[9];
    // wire [31:0] a0 = reg_val[10];
    // wire [31:0] a1 = reg_val[11];
    // wire [31:0] a2 = reg_val[12];
    // wire [31:0] a3 = reg_val[13];
    // wire [31:0] a4 = reg_val[14];
    // wire [31:0] a5 = reg_val[15];
    // wire [31:0] a6 = reg_val[16];
    // wire [31:0] a7 = reg_val[17];
    // wire [31:0] s2 = reg_val[18];
    // wire [31:0] s3 = reg_val[19];
    // wire [31:0] s4 = reg_val[20];
    // wire [31:0] s5 = reg_val[21];
    // wire [31:0] s6 = reg_val[22];
    // wire [31:0] s7 = reg_val[23];
    // wire [31:0] s8 = reg_val[24];
    // wire [31:0] s9 = reg_val[25];
    // wire [31:0] s10 = reg_val[26];
    // wire [31:0] s11 = reg_val[27];
    // wire [31:0] t3 = reg_val[28];
    // wire [31:0] t4 = reg_val[29];
    // wire [31:0] t6 = reg_val[31];
    // wire [31:0] t5 = reg_val[30];
    


    integer i;
    assign qry_r1_val = (is_update_val && update_val_id == qry_r1_id) ? update_val : reg_val[qry_r1_id];
    assign qry_r2_val = (is_update_val && update_val_id == qry_r2_id) ? update_val : reg_val[qry_r2_id];
    assign qry_r1_dep = (is_update_dep && update_dep_id == qry_r1_id) ? update_dep : reg_dep[qry_r1_id];
    assign qry_r2_dep = (is_update_dep && update_dep_id == qry_r2_id) ? update_dep : reg_dep[qry_r2_id];
    // these 2 may be wrong when the has_dep is false
    assign qry_r1_has_dep = (is_update_dep && update_dep_id == qry_r1_id) ? 1 : ((is_update_val && update_val_id == qry_r1_id && reg_dep[update_val_id] == update_val_dep) ? 0 : has_dep[qry_r1_id]);
    assign qry_r2_has_dep = (is_update_dep && update_dep_id == qry_r2_id) ? 1 : ((is_update_val && update_val_id == qry_r2_id && reg_dep[update_val_id] == update_val_dep) ? 0 : has_dep[qry_r2_id]);

always @(posedge clk_in or posedge rst_in) 
begin
    if (rst_in) begin
        for(i = 0; i < `ROB_SIZE; i = i + 1) begin
            reg_val[i] <= 0;
            reg_dep[i] <= 0;
            has_dep[i] <= 0;
        end
    end
    else if (rdy_in) 
    begin
        if(rob_clear) begin
            for(i = 0; i < `ROB_SIZE; i = i + 1) begin
                reg_dep[i] <= 0;
                has_dep[i] <= 0;
            end
        end
        else begin
            if(is_update_val) begin
                reg_val[update_val_id] <= update_val;
                if(!has_dep[update_val_id])
                    $display("Warning: RF update value without dependency");  
                // if(update_val_id != update_dep_id)
                //     $display("Warning: MAYBE ROB is completely full, pop one and push one");
                if(reg_dep[update_val_id] == update_val_dep && (!is_update_dep || update_val_id != update_dep_id)) begin
                    has_dep[update_val_id] <= 0;
                end
            end
            if(is_update_dep) begin
                reg_dep[update_dep_id] <= update_dep;
                has_dep[update_dep_id] <= 1;
            end
        end
    end
end
endmodule