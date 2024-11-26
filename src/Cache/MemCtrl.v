module MemCtrl(
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    input wire rob_clear,
    // the memory write back operation should not be influence by the rob_clear signal
    //!!!!!!!!! WARNING !!!!!!!!! 


    // interaction with the outside
    input wire new_task, // if need to start a new work
    input wire is_write, // if write
    input wire [31:0] addr, // the address
    input wire [31:0] data_in, // the data, if write
    output wire [31:0] data_out, // the data
    input wire [2:0] work_type,

    output wire real_ready_out, // if the data is ready
    output reg is_working, // if has current work

    // first bit: signed or unsigned (0: unsigned, 1: signed)
    // second 2 bit : 00: byte, 01: half word, 10: word


    // interaction with the memory
    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)
	input  wire                 io_buffer_full // 1 if uart buffer is full
    // output wire mem_valid, // if need to work
    // output wire mem_is_write, // if write
    // output wire [31:0] mem_addr, // the address
    // input wire [7:0] mem_data_in, // the data, if write
    // output wire [7:0] mem_data_out, // the data
 
);
    reg cur_is_write;
    reg ready_out; // if the data is ready
    reg [31:0] cur_addr;
    reg [31:0] cur_data_in;
    reg [31:0] cur_data_out;
    reg [2:0] cur_work_type;
    reg [1:0]cur_state;
    assign mem_a = new_task ? addr : (!is_working ? 0 : cur_addr + cur_state + 1);
    assign mem_wr = new_task ? is_write : (!is_working ? 0 : cur_is_write);
    // wire [4:0] start_pos = cur_state << 3;
    // wire [4:0] end_pos = start_pos + 7;
    wire [7:0] switch_data = (cur_state == 2'b00) ? cur_data_in[15:8] :
        (cur_state == 2'b01) ? cur_data_in[23:16] :
        cur_data_in[31:24];

    // assign mem_dout = new_task ? data_in[7:0] : cur_data_in[end_pos:start_pos];
    assign mem_dout = new_task ? data_in[7:0] : switch_data;


    assign real_ready_out = (rob_clear && !cur_is_write) ? 0 : ready_out;
    // the read offset

    wire [31:0] data_out_b = {{24{mem_din[7]}}, mem_din[7:0]};
    wire [31:0] data_out_bu = {{24'b0}, mem_din[7:0]};
    wire [31:0] data_out_h = {{16{mem_din[7]}}, mem_din[7:0], cur_data_out[7:0]};
    wire [31:0] data_out_hu = {{16'b0}, mem_din[7:0], cur_data_out[7:0]};
    wire [31:0] data_out_w = {{mem_din[7:0], cur_data_out[23:0]}};   

    assign data_out = (!cur_work_type[2]) ? 
        ((cur_work_type[1:0] == 2'b00) ? data_out_b :
        (cur_work_type[1:0] == 2'b01) ? data_out_h :
        data_out_w ):
        ((cur_work_type[1:0] == 2'b00) ? data_out_bu :
        (cur_work_type[1:0] == 2'b01) ? data_out_hu :
        0);
    reg is_read_last_moment;
always @(posedge clk_in)
begin
    if (rst_in)
    begin
        is_working <= 0;
        ready_out <= 0;
        is_read_last_moment <= 0;
    end
else if (rdy_in)
    begin
        if(is_working && new_task && !rob_clear) begin
            $display("Warning: new task is coming while the last one is not finished, while not rob_clear");
        end
        if(new_task) begin
            if(io_buffer_full) begin
                $display("Warning: new task is coming while the buffer is full");
            end
            cur_is_write <= is_write;
            cur_addr <= addr;
            cur_data_in <= data_in;
            cur_work_type <= work_type;
            cur_state <= 2'b00;
            is_read_last_moment <= 1;
            if(work_type[1:0] == 2'b00) begin
                is_working <= 0;
                ready_out <= !is_write;
            end 
            else begin
                is_working <= 1;
                ready_out <= 0;
            end
        end 
        else if(is_working) begin
            if(is_read_last_moment)begin
                case (cur_state) 
                    2'b00: cur_data_out[7:0] <= mem_din;
                    2'b01: cur_data_out[15:8] <= mem_din;
                    2'b10: cur_data_out[23:16] <= mem_din;
                    2'b11: cur_data_out[31:24] <= mem_din;
                endcase
            end
            if(!io_buffer_full) begin
                if(cur_state == cur_work_type[1:0] || (rob_clear && !cur_is_write)) begin
                    is_working <= 0;
                    ready_out <= !cur_is_write && !rob_clear;
                end
                cur_state <= cur_state + 1;
                is_read_last_moment <= 1;
            end 
            else begin
                is_read_last_moment <= 0;
            end
            // cur_data_out[end_pos:start_pos] <= mem_dout;
        end 
        
        if(!is_working && !new_task) begin
            ready_out <= 0;
            is_read_last_moment <= 0;
        end
    end
end

endmodule