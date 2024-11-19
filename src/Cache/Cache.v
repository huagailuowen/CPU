`include "Config.v"

module Cache(
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	

    input wire rob_clear,
    // the memory write back operation should not be influence by the rob_clear signal
    //!!!!!!!!! WARNING !!!!!!!!! 

    input wire need_inst, // if need instruction
    input wire [31:0] inst_addr,
    output wire inst_handle, // if the instruction is handled
    output wire inst_ready, // if the instruction is ready
    output wire [31:0] inst_out, // the instruction

    input wire need_data, // if need data
    input wire is_write, // if write
    input wire [31:0] data_addr,
    input wire [31:0] data_in, // the data
    input wire [2:0] work_type, 
    // first bit: signed or unsigned (0: unsigned, 1: signed)
    // second 2 bit : 00: byte, 01: half word, 10: word
    output wire data_handle, // if the data_work is handled
    output wire data_ready, // if the data is ready
    output wire [31:0] data_out // the data
    
    //the data is with priority ?
    // the handle must calculate in this cycle
    // the ic instruction is handled by the fetcher
);
    wire i_hit;
    wire [31:0] i_data;
    InstCache inst_cache(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        
        .addr(inst_addr),
        .is_hit(i_hit),
        .data_out(i_data),

        .is_update(mc_ready_out && !is_data),
        .data_in(inst_out),
        .addr_in(cur_addr)
    );
    wire [31:0] mc_out;
    wire mc_is_working;
    wire mc_ready_out;
    
    wire mc_is_write = is_handle_data ? is_write : 0;
    wire [31:0] mc_addr = is_handle_data ? data_addr : inst_addr;
    wire [2:0] mc_work_type = is_handle_data ? work_type : 3'b010;
    MemCtrl mem_ctrl(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        .mem_din(mem_din),
        .mem_dout(mem_dout),
        .mem_a(mem_a),
        .mem_wr(mem_wr),
        .io_buffer_full(io_buffer_full),
        .rob_clear(rob_clear),
        
        .new_task(need_handle), 
        .is_write(mc_is_write), 
        .addr(mc_addr), 
        .data_in(data_in), 
        .data_out(mc_out),
        .work_type(mc_work_type),
        .real_ready_out(mc_ready_out),
        .is_working(mc_is_working)
    );


    // reg is_working;
    // reg ready_out;
    reg is_data;
    reg [31:0] cur_addr;
    wire able_handle = !mc_is_working && !rob_clear;
    wire need_handle = able_handle && (need_inst && !i_hit || need_data);
    // refer to is mc need handle, not contain the hit 
    wire is_handle_data = need_data;
    // data_fetch is with priority
    assign inst_handle = (need_inst && i_hit) ? 1 : need_handle && !is_handle_data;
    assign data_handle = need_handle && is_handle_data;
    
    // when rob_clear, only the ICache is working
    assign inst_ready = (need_inst && i_hit) ? 1 : !rob_clear && mc_ready_out && !is_data; 
    assign inst_out = (need_inst && i_hit) ? i_data : mc_out;
    assign data_ready = !rob_clear && mc_ready_out && is_data;
    assign data_out = mc_out;

always @(posedge clk_in)
begin
if (rst_in || rdy_in && rob_clear)
    begin
        // not need to do anything, all the reset thing is done in the sub module mem_ctrl
    end
else if(rdy_in)
    begin
        if(need_handle) begin 
            is_data <= is_handle_data;
            cur_addr <= mc_addr;
        end
    end    
end
endmodule