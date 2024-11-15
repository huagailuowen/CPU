// RISCV32 CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)


    //Debugger

    assign dbgreg_dout[31:0] = decoder_next_PC;

    // ROB
    wire rob_full;
    wire [`ROB_SIZE_BIT-1:0]rob_free_id;
    wire [`ROB_SIZE_BIT-1:0] rob_head_id;
    wire rob_clear;
    wire [31:0] rob_rst_addr;
    wire rob_qry1_ready;
    wire [31:0] rob_qry1_value;
    wire rob_qry2_ready;
    wire [31:0] rob_qry2_value;
    wire rob_is_update_val;
    wire [4:0] rob_update_val_id;
    wire [`ROB_SIZE_BIT-1:0] rob_update_val_dep;
    wire [31:0] rob_update_val;
    wire rob_is_update_dep;
    wire [4:0] rob_update_dep_id;
    wire [`ROB_SIZE_BIT-1:0] rob_update_dep;
    ROB rob(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .rob_full(rob_full),
        .rob_free_id(rob_free_id),
        .rob_head_id(rob_head_id),
        .rob_clear(rob_clear),
        .rob_rst_addr(rob_rst_addr),

        .rob_input(decoder_rob_input),
        .rob_value(decoder_rob_value),
        .rob_addr(decoder_rob_addr),
        .rob_type(decoder_rob_type),
        .rob_reg_id(decoder_rob_reg_id),
        .rob_fi(decoder_rob_fi),

        .rob_qry1_id(decoder_rob_qry1_id),
        .rob_qry1_ready(rob_qry1_ready),
        .rob_qry1_value(rob_qry1_value),
        .rob_qry2_id(decoder_rob_qry2_id),
        .rob_qry2_ready(rob_qry2_ready),
        .rob_qry2_value(rob_qry2_value),

        .rs_fi(alu_fi),
        .rs_value(alu_res),
        .rs_rob_id(alu_cur_rob_id),
        .lsb_fi(lsb_fi),
        .lsb_value(lsb_value),
        .lsb_rob_id(lsb_rob_id),

        .is_update_val(rob_is_update_val),
        .update_val_id(rob_update_val_id),
        .update_val_dep(rob_update_val_dep),
        .update_val(rob_update_val),
        .is_update_dep(rob_is_update_dep),
        .update_dep_id(rob_update_dep_id),
        .update_dep(rob_update_dep)
    );

    // RF

    wire [31:0] rf_qry_r1_val;
    wire [31:0] rf_qry_r2_val;
    wire [`ROB_SIZE_BIT-1:0] rf_qry_r1_dep;
    wire [`ROB_SIZE_BIT-1:0] rf_qry_r2_dep;
    wire rf_qry_r1_has_dep;
    wire rf_qry_r2_has_dep;

    RF rf(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        .rob_clear(rob_clear),
        .is_update_val_in(rob_is_update_val),
        .update_val_id(rob_update_val_id),
        .update_val_dep(rob_update_val_dep),
        .update_val(rob_update_val),

        .is_update_dep_in(rob_is_update_dep),
        .update_dep_id(rob_update_dep_id),
        .update_dep(rob_update_dep),

        .qry_r1_id(decoder_rs1_id),
        .qry_r2_id(decoder_rs2_id),
        .qry_r1_val(rf_qry_r1_val),
        .qry_r2_val(rf_qry_r2_val),
        .qry_r1_dep(rf_qry_r1_dep),
        .qry_r2_dep(rf_qry_r2_dep),
        .qry_r1_has_dep(rf_qry_r1_has_dep),
        .qry_r2_has_dep(rf_qry_r2_has_dep)
    );

    // RS

    wire rs_full;
    wire rs_alu_input;
    wire [`RS_TYPE_BIT-1:0] rs_arith_type;
    wire [31:0] rs_r1_val;
    wire [31:0] rs_r2_val;
    wire [`ROB_SIZE_BIT-1:0] rs_inst_rob_id;

    RS rs(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        .rs_full(rs_full),
        .rob_clear(rob_clear),

        .inst_input(decoder_rs_input),
        .rs_type(decoder_rs_type),
        .rs_r1_val(decoder_rs_r1_val),
        .rs_r2_val(decoder_rs_r2_val),
        .rs_r1_has_dep(decoder_rs_r1_has_dep),
        .rs_r2_has_dep(decoder_rs_r2_has_dep),
        .rs_r1_dep(decoder_rs_r1_dep),
        .rs_r2_dep(decoder_rs_r2_dep),
        .rs_rob_id_in(decoder_rs_rob_id),

        .rs_fi(alu_fi),
        .rs_value(alu_res),
        .rs_rob_id(alu_cur_rob_id),
        .lsb_fi(lsb_fi),
        .lsb_value(lsb_value),
        .lsb_rob_id(lsb_rob_id),

        .alu_input(rs_alu_input),
        .arith_type(rs_arith_type),
        .alu_r1_val(rs_r1_val),
        .alu_r2_val(rs_r2_val),
        .inst_rob_id(rs_inst_rob_id)
    );

    // ALU

    wire alu_fi;
    wire [`ROB_SIZE_BIT-1:0] alu_cur_rob_id;
    wire [31:0] alu_res;
    ALU alu(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        .alu_input(rs_alu_input),
        .arith_type(rs_arith_type),
        .r1_val(rs_r1_val),
        .r2_val(rs_r2_val),
        .inst_rob_id(rs_inst_rob_id),

        .alu_fi(alu_fi),
        .cur_rob_id(alu_cur_rob_id),
        .res(alu_res),

        .rob_clear(rob_clear)
    );

    // LSB
     
    wire lsb_full;
    wire lsb_fi;
    wire [31:0] lsb_value;
    wire [`ROB_SIZE_BIT-1:0] lsb_rob_id;
    wire lsb_need_data;
    wire lsb_is_write;
    wire [31:0] lsb_data_addr;
    wire [31:0] lsb_data_in;
    wire [2:0] lsb_work_type;

    LSB lsb(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        .rob_clear(rob_clear),
        .rob_head_id(rob_head_id),
        .lsb_full(lsb_full),

        .inst_input(decoder_lsb_input),
        .lsb_type(decoder_lsb_type),
        .lsb_r1_val(decoder_lsb_r1_val),
        .lsb_r2_val(decoder_lsb_r2_val),
        .lsb_r1_has_dep(decoder_lsb_r1_has_dep),
        .lsb_r2_has_dep(decoder_lsb_r2_has_dep),
        .lsb_r1_dep(decoder_lsb_r1_dep),
        .lsb_r2_dep(decoder_lsb_r2_dep),
        .lsb_imm(decoder_lsb_imm),
        .lsb_rob_id_in(decoder_lsb_rob_id),

        .lsb_fi(lsb_fi),
        .lsb_value(lsb_value),
        .lsb_rob_id(lsb_rob_id),
        .rs_fi(alu_fi),
        .rs_value(alu_res),
        .rs_rob_id(alu_cur_rob_id),

        .need_data(lsb_need_data),
        .is_write(lsb_is_write),
        .data_addr(lsb_data_addr),
        .data_in(lsb_data_in),
        .work_type(lsb_work_type),
        .data_handle(cache_data_handle),
        .data_ready(cache_data_ready),
        .data_out(cache_data_out)
    );

    // Fetcher

    wire fetcher_inst_ready_out;
    wire [31:0] fetcher_inst_out;
    wire [31:0] fetcher_inst_addr_out;
    wire fetcher_inst_req;
    wire [31:0] fetcher_inst_addr;

    Fetcher fetcher(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        .next_PC(decoder_next_PC),
        .is_stall(decoder_is_stall),
        .inst_ready_out(fetcher_inst_ready_out),
        .inst_out(fetcher_inst_out),
        .inst_addr_out(fetcher_inst_addr_out),

        .inst_req(fetcher_inst_req),
        .inst_addr(fetcher_inst_addr),
        .inst_handle(cache_inst_handle),
        .inst_ready_in(cache_inst_ready),
        .inst_in(cache_inst_out),

        .rob_clear(rob_clear),
        .rob_rst_addr(rob_rst_addr)
    );

    // Decoder

    wire decoder_is_stall;
    wire [31:0] decoder_next_PC;
    wire [4:0] decoder_rs1_id;
    wire [4:0] decoder_rs2_id;
    wire [4:0] decoder_rob_qry1_id;
    wire [4:0] decoder_rob_qry2_id;
    wire                     decoder_rob_input;
    wire                     decoder_rob_fi;   
    wire [31:0]              decoder_rob_value;
    wire [31:0]              decoder_rob_addr; 
    wire [`ROB_TYPE_BIT-1:0]  decoder_rob_type; 
    wire [4:0]               decoder_rob_reg_id;
    wire                     decoder_rs_input;     
    wire [`RS_TYPE_BIT-1:0]  decoder_rs_type;       
    wire [31:0]              decoder_rs_r1_val;    
    wire [31:0]              decoder_rs_r2_val;
    wire                     decoder_rs_r1_has_dep;
    wire                     decoder_rs_r2_has_dep;
    wire [`ROB_SIZE_BIT-1:0]  decoder_rs_r1_dep;
    wire [`ROB_SIZE_BIT-1:0]  decoder_rs_r2_dep;
    wire [`ROB_SIZE_BIT-1:0]  decoder_rs_rob_id;

    wire                     decoder_lsb_input;     
    wire [`LSB_TYPE_BIT-1:0] decoder_lsb_type;       
    wire [31:0]              decoder_lsb_r1_val;    
    wire [31:0]              decoder_lsb_r2_val;
    wire                     decoder_lsb_r1_has_dep;
    wire                     decoder_lsb_r2_has_dep;
    wire [`ROB_SIZE_BIT-1:0]  decoder_lsb_r1_dep;
    wire [`ROB_SIZE_BIT-1:0]  decoder_lsb_r2_dep;
    wire [31:0]              decoder_lsb_imm;
    wire [`ROB_SIZE_BIT-1:0]  decoder_lsb_rob_id;

    Decoder decoder(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        .inst_input(fetcher_inst_ready_out),
        .inst(fetcher_inst_out),
        .inst_addr(fetcher_inst_addr_out),
        .is_stall(decoder_is_stall),
        .next_PC(decoder_next_PC),

        .rs1_val(rf_qry_r1_val),
        .rs2_val(rf_qry_r2_val),
        .rs1_has_dep(rf_qry_r1_has_dep),
        .rs2_has_dep(rf_qry_r2_has_dep),
        .rs1_dep(rf_qry_r1_dep),
        .rs2_dep(rf_qry_r2_dep),
        .rs1_id(decoder_rs1_id),
        .rs2_id(decoder_rs2_id),

        .rob_qry1_id(decoder_rob_qry1_id),
        .rob_qry1_fi(rob_qry1_ready),
        .rob_qry1_value(rob_qry1_value),
        .rob_qry2_id(decoder_rob_qry2_id),
        .rob_qry2_fi(rob_qry2_ready),
        .rob_qry2_value(rob_qry2_value),

        .rob_full(rob_full),
        .rob_clear(rob_clear),
        .rob_vacant_id(rob_free_id),

        .rob_input(decoder_rob_input),
        .rob_fi(decoder_rob_fi),
        .rob_value(decoder_rob_value),
        .rob_addr(decoder_rob_addr),
        .rob_type(decoder_rob_type),
        .rob_reg_id(decoder_rob_reg_id),

        .rs_full(rs_full),
        .rs_input(decoder_rs_input),
        .rs_type(decoder_rs_type),
        .rs_r1_val(decoder_rs_r1_val),
        .rs_r2_val(decoder_rs_r2_val),
        .rs_r1_has_dep(decoder_rs_r1_has_dep),
        .rs_r2_has_dep(decoder_rs_r2_has_dep),
        .rs_r1_dep(decoder_rs_r1_dep),
        .rs_r2_dep(decoder_rs_r2_dep),
        .rs_rob_id(decoder_rs_rob_id),

        .lsb_full(lsb_full),
        .lsb_input(decoder_lsb_input),
        .lsb_type(decoder_lsb_type),
        .lsb_r1_val(decoder_lsb_r1_val),
        .lsb_r2_val(decoder_lsb_r2_val),
        .lsb_r1_has_dep(decoder_lsb_r1_has_dep),
        .lsb_r2_has_dep(decoder_lsb_r2_has_dep),
        .lsb_r1_dep(decoder_lsb_r1_dep),
        .lsb_r2_dep(decoder_lsb_r2_dep),
        .lsb_imm(decoder_lsb_imm),
        .lsb_rob_id(decoder_lsb_rob_id)
    );
    // Cache

    wire cache_mem_dout;
    wire [31:0] cache_mem_a;
    wire cache_mem_wr;
    wire cache_inst_handle;
    wire cache_inst_ready;
    wire [31:0] cache_inst_out;
    wire cache_data_handle;
    wire cache_data_ready;
    wire [31:0] cache_data_out;

    Cache cache(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        .mem_din(mem_din),
        .mem_dout(mem_dout),
        .mem_a(mem_a),
        .mem_wr(mem_wr),
        .io_buffer_full(io_buffer_full),

        .rob_clear(rob_clear),
        .need_inst(fetcher_inst_req),
        .inst_addr(fetcher_inst_addr),
        .inst_handle(cache_inst_handle),
        .inst_ready(cache_inst_ready),
        .inst_out(cache_inst_out),

        .need_data(lsb_need_data),
        .is_write(lsb_is_write),
        .data_addr(lsb_data_addr),
        .data_in(lsb_data_in),
        .work_type(lsb_work_type),
        .data_handle(cache_data_handle),
        .data_ready(cache_data_ready),
        .data_out(cache_data_out)
    );

always @(posedge clk_in)
begin
    if (rst_in)begin
      
    end
    else if (!rdy_in) begin
      
    end
    else begin
      
    end
end

endmodule