`include "Config.v"
module LSB(

    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    input wire rob_clear,  // clear the ROB signal
    input wire [`ROB_SIZE_BIT-1:0] rob_head_id,  // the ROB id of the head instruction
    output wire lsb_full,  // lsb full signal

    // interaction with Decoder
    input wire inst_input,  // the input signal of Decoder
    input wire [`LSB_TYPE_BIT-1:0] lsb_type,  // the type of the instruction
    //[1:is_write] [3:func3]

    input wire [31:0] lsb_r1_val,  // the value of lsb1
    input wire [31:0] lsb_r2_val,  // the value of lsb2
    input wire lsb_r1_has_dep,  // does lsb1 has dependency
    input wire lsb_r2_has_dep,  // does lsb2 has dependency
    input wire [`ROB_SIZE_BIT-1:0] lsb_r1_dep,  // the ROB id of the dependency
    input wire [`ROB_SIZE_BIT-1:0] lsb_r2_dep,  // the ROB id of the dependency
    input wire [31:0] lsb_imm,  // the immediate value of the instruction
    input wire [`ROB_SIZE_BIT-1:0] lsb_rob_id_in, // the ROB id of the instruction
    // input wire [4:0] lsb_rd_id,  // the rd id of the instruction


    // output to the cd_bus
    output wire lsb_fi,
    output wire [31:0] lsb_value,
    output wire [`ROB_SIZE_BIT-1:0] lsb_rob_id,
    input wire rs_fi,
    input wire [31:0] rs_value,
    input wire [`ROB_SIZE_BIT-1:0] rs_rob_id,

    // interaction with Cache
    output wire need_data, // if need data
    output wire is_write, // if write
    output wire [31:0] data_addr,
    output wire [31:0] data_in, // the data
    output wire [2:0] work_type,
    input wire data_handle, // if the data_work is handled
    input wire data_ready, // if the data is ready
    input wire [31:0] data_out // the data
);
    assign is_write = type[head][3];
    assign data_addr = r1_val[head] + imm[head];
    assign data_in = r2_val[head];
    assign work_type = type[head][2:0];
    assign need_data = !rob_clear && lsb_size > 0 && ready[head] && !(need_confirm && rob_head_id != rob_id[head]) && state[head] == Nready;

    wire need_confirm = is_write || data_addr[17:16] == 2'b11;

    localparam LSB_SIZE_MAX = 6'b001000;
    localparam Nready = 2'b00;
    // localparam Request = 2'b01;
    localparam Executing = 2'b10;
    localparam Finished = 2'b11;
    reg [5:0] lsb_size;
    wire ready[0:`LSB_SIZE-1];
    reg [1:0] state[0:`LSB_SIZE-1];

    wire is_pop = lsb_size > 0 && (is_write && data_handle || !is_write && data_ready);
    assign lsb_fi = !rob_clear && is_pop;
    // however if the there is a rob_clear then the cache should also stop the read operation, but the write should not stop!!!!! 
    // !!!!!!!!!!!!!!WARNING!!!!!!!!!!!!!!
    assign lsb_value = data_out;
    assign lsb_rob_id = rob_id[head];
    /* for load, executing means the cache accept the request, 
        finished means the cache return the data,
        we just send it to cd_bus immediately */
    
    /* for store, executing means , 
        executing means rob approve the request(rob_head_id == lsb_rob_id),
        finished means cache handle the request,
        we just remove it immediately */

    reg [31:0] r1_val[0:`LSB_SIZE-1];
    reg [31:0] r2_val[0:`LSB_SIZE-1];
    reg r1_has_dep[0:`LSB_SIZE-1];
    reg r2_has_dep[0:`LSB_SIZE-1];
    reg [`ROB_SIZE_BIT-1:0] r1_dep[0:`LSB_SIZE-1];
    reg [`ROB_SIZE_BIT-1:0] r2_dep[0:`LSB_SIZE-1];
    reg [`ROB_SIZE_BIT-1:0] rob_id[0:`LSB_SIZE-1];
    reg [`LSB_TYPE_BIT-1:0] type[0:`LSB_SIZE-1];
    reg [31:0] imm[0:`LSB_SIZE-1];
    reg finished[0:`LSB_SIZE-1];
    reg [`LSB_SIZE_BIT-1:0] head, tail;


    assign lsb_full = (lsb_size == LSB_SIZE_MAX) || (lsb_size + 1 == LSB_SIZE_MAX && inst_input && !finished[head]);

    wire tmp_lsb_r1_has_dep = (rs_fi && lsb_r1_has_dep && rs_rob_id == lsb_r1_dep) ? 0 : ((lsb_fi && lsb_r1_has_dep && lsb_rob_id == lsb_r1_dep) ? 0 : lsb_r1_has_dep);
    wire [31:0] tmp_lsb_r1_val = (rs_fi && lsb_r1_has_dep && rs_rob_id == lsb_r1_dep) ? rs_value : ((lsb_fi && lsb_r1_has_dep && lsb_rob_id == lsb_r1_dep) ? lsb_value : lsb_r1_val);
    wire tmp_lsb_r2_has_dep = (rs_fi && lsb_r2_has_dep && rs_rob_id == lsb_r2_dep) ? 0 : ((lsb_fi && lsb_r2_has_dep && lsb_rob_id == lsb_r2_dep) ? 0 : lsb_r2_has_dep);
    wire [31:0] tmp_lsb_r2_val = (rs_fi && lsb_r2_has_dep && rs_rob_id == lsb_r2_dep) ? rs_value : ((lsb_fi && lsb_r2_has_dep && lsb_rob_id == lsb_r2_dep) ? lsb_value : lsb_r2_val);    

    genvar gi;
    generate
        for(gi = 0; gi < `RS_SIZE; gi = gi + 1) begin
            assign ready[gi] = !r1_has_dep[gi] && !r2_has_dep[gi];
        end 
    endgenerate


integer i;
always @(posedge clk_in or posedge rst_in) 
begin
    if (rst_in) begin
        for(i = 0; i < `LSB_SIZE; i = i + 1) begin
            state[i] <= Nready;
            r1_val[i] <= 32'b0;
            r2_val[i] <= 32'b0;
            r1_has_dep[i] <= 1'b0;
            r2_has_dep[i] <= 1'b0;
            r1_dep[i] <= 5'b0;
            r2_dep[i] <= 5'b0;
            type[i] <= 4'b0;
            imm[i] <= 32'b0;
            rob_id[i] <= 5'b0;
        end
        head <= 0;
        tail <= 0;
        lsb_size <= 0;
    end
    else if (rdy_in) 
    begin
        if(rob_clear) begin
            head <= 0;
            tail <= 0;
            lsb_size <= 0;
            // if(lsb_size > 0 && !finished[head] && type[head] == `LSB_ST) begin
            //     tail <= head + 1;
            //     lsb_size <= 1;
            // end
            // else begin
            //     tail <= head;
            //     lsb_size <= 0;
            // end
        end 
        else begin
            lsb_size <= lsb_size + inst_input - is_pop;
            if(inst_input) begin
                state[tail] <= Nready;
                r1_val[tail] <= tmp_lsb_r1_val;
                r2_val[tail] <= tmp_lsb_r2_val;
                r1_has_dep[tail] <= tmp_lsb_r1_has_dep;
                r2_has_dep[tail] <= tmp_lsb_r2_has_dep;
                r1_dep[tail] <= lsb_r1_dep;
                r2_dep[tail] <= lsb_r2_dep;
                type[tail] <= lsb_type;
                imm[tail] <= lsb_imm;
                rob_id[tail] <= lsb_rob_id_in;
                tail <= tail + 1;
            end
            for(i = 0; i < `LSB_SIZE; i = i + 1) begin
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

            // working the first instruction, strictly follow the order
            if(is_pop) begin
                head <= head + 1;
            end
            if(need_data) begin
                if(!is_write && data_handle || is_write && !is_pop) begin
                    // when it is write and data handle, we just remove it !!!! 
                    // or when lsb_full something wrong
                    state[head] <= Executing;
                end
            end 
        end
    end
end
endmodule