`include "Config.v"

module ROB (

    input wire clk_in, // system clock signal
    input wire rst_in, // reset signal
    input wire rdy_in, // ready signal, pause cpu when low

    

    output wire rob_full, // ROB full signal
    output wire [`ROB_SIZE_BIT-1:0]rob_free_id, // the ROB id of the next instruction
    output wire [`ROB_SIZE_BIT-1:0] rob_head_id, // the ROB id of the head instruction
    output reg rob_clear, // clear the ROB
    output reg [31:0] rob_rst_addr, // the address of the instruction, for restarting ROB

    // interaction with Decoder
    //FROM
    input wire rob_input, // the input signal of ROB
    input wire [31:0] rob_value, // in case that the ins is a lui etc.
    input wire [31:0] rob_addr, // the address of the instruction, for restarting ROB
    input wire [`ROB_TYPE_BIT-1:0] rob_type, // the type of the instruction
    input wire [4:0] rob_reg_id, // the reg id of the instruction
    input wire rob_fi, // is the instruction has finished, like lui

    //TO
    input wire [`ROB_SIZE_BIT-1:0] rob_qry1_id, // the ROB id of the instruction
    output wire rob_qry1_ready, // if the instruction has been finished
    output wire [31:0] rob_qry1_value, // the value of the instruction, if finished
    input wire [`ROB_SIZE_BIT-1:0] rob_qry2_id, // the ROB id of the instruction
    output wire rob_qry2_ready, // if the instruction has been finished
    output wire [31:0] rob_qry2_value, // the value of the instruction, if finished



    // interaction with RS
    input wire rs_fi, // the output signal of RS
    input wire [31:0] rs_value, // the output value of RS
    // input wire [4:0] rs_rd_id, // the rd id of the instruction
    input wire [`ROB_SIZE_BIT-1:0] rs_rob_id, // the ROB id of the instruction

    // interaction with LSB
    // output reg write_back,     // write back signal

    input wire lsb_fi, // the output signal of LSB
    input wire [31:0] lsb_value, // the output value of LSB
    // input wire [4:0] lsb_rd_id, // the rd id of the instruction
    input wire [`ROB_SIZE_BIT-1:0] lsb_rob_id, // the ROB id of the instruction


    // interaction with RF
    output wire is_update_val,
    output wire [4:0] update_val_id,
    output wire [`ROB_SIZE_BIT-1:0] update_val_dep,
    output wire [31:0] update_val,
    output wire is_update_dep,
    output wire [4:0] update_dep_id,
    output wire [`ROB_SIZE_BIT-1:0] update_dep

);
    wire rob_empty = rob_size == 0;
    reg [`ROB_SIZE_BIT-1:0] head;
    reg [`ROB_SIZE_BIT-1:0] tail; 
    reg [4:0] rd_id[0:`ROB_SIZE-1];
    // for the branch, rd_id is the predicted value
    reg is_finished[0:`ROB_SIZE-1];
    reg [31:0] res[0:`ROB_SIZE-1];
    reg [31:0] inst_addr[0:`ROB_SIZE-1];
    //only for branch, store the other branch address

    reg [`ROB_TYPE_BIT-1:0] type[0:`ROB_SIZE-1];

    reg [5:0] rob_size;

    localparam ROB_SIZE_MAX = 6'b100000;
    assign rob_full = rob_size == ROB_SIZE_MAX || (rob_size == ROB_SIZE_MAX - 1 && !(is_finished[head] && !rob_empty) && rob_input);
    assign rob_free_id = rob_clear ? 0 : (rob_input ? tail + 1 : tail);
    wire is_pop = is_finished[head] && !rob_empty;
    assign rob_head_id = rob_clear ? 0 : (is_pop ? head+1 : head);
    // handle the query, 
    assign rob_qry1_ready = (rob_input && tail == rob_qry1_id)? rob_fi : is_finished[rob_qry1_id];
    assign rob_qry1_value = (rob_input && tail == rob_qry1_id)? rob_value : res[rob_qry1_id];
    assign rob_qry2_ready = (rob_input && tail == rob_qry2_id)? rob_fi : is_finished[rob_qry2_id];
    assign rob_qry2_value = (rob_input && tail == rob_qry2_id)? rob_value : res[rob_qry2_id];
    // interaction with RF
    assign is_update_val = is_pop && (type[head] == `ROB_REG || type[head] == `ROB_REGI);
    assign update_val_id = rd_id[head];
    assign update_val_dep = head;
    assign update_val = res[head];
    assign is_update_dep = rob_input && (rob_type == `ROB_REG || rob_type == `ROB_REGI); 
    assign update_dep_id = rob_reg_id;
    assign update_dep = tail;

    integer i;
always @(posedge clk_in or posedge rst_in) 
begin
    if (rst_in ) begin
        head <= 0;
        tail <= 0;
        rob_size <= 0;
        // write_back <= 0;
        for(i = 0; i < `ROB_SIZE; i = i + 1) begin
            is_finished[i] <= 0;
            res[i] <= 0;
            inst_addr[i] <= 0;
            rd_id[i] <= 0;
            type[i] <= 0;
        end
    end
    else if (rdy_in) 
    begin
        if(rob_clear) begin
            // write_back <= 0;
            head <= 0;
            tail <= 0;
            rob_size <= 0;
            for(i = 0; i < `ROB_SIZE; i = i + 1) begin
                is_finished[i] <= 0;
                res[i] <= 0;
                inst_addr[i] <= 0;
                rd_id[i] <= 0;
                type[i] <= 0;
            end
        end
        else begin
            if(rob_input && !is_pop) begin
                rob_size <= rob_size + 1;
            end
            else if(!rob_input && is_pop) begin
                rob_size <= rob_size - 1;
            end
            // write_back <= is_pop && type[head] == `ROB_ST;
            if(rob_input) begin
                inst_addr[tail] <= rob_addr;
                rd_id[tail] <= rob_reg_id;
                type[tail] <= rob_type;
                is_finished[tail] <= rob_fi;
                res[tail] <= rob_value;
                tail <= tail + 1;
            end
            if(rs_fi) begin
                is_finished[rs_rob_id] <= 1;
                res[rs_rob_id] <= rs_value;
            end
            if(lsb_fi) begin
                is_finished[lsb_rob_id] <= 1;
                res[lsb_rob_id] <= lsb_value;
            end 
            if(is_pop) begin
                head <= head + 1;
                case (type[head]) 
                    `ROB_BR : begin
                        if(res[head] != rd_id[head]) begin
                            rob_clear <= 1;
                            rob_rst_addr <= inst_addr[head];
                        end
                    end
                endcase

            end
        end
    end
end

endmodule