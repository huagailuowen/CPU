`include "Config.v"

module Decoder (
    input wire  clk_in,			// system clock signal
    input wire  rst_in,			// reset signal
	input wire  rdy_in,			// ready signal, pause cpu when low

    input wire inst_input,	// instruction input
    input wire [31:0] inst,	    // instruction input
    input wire [31:0] inst_addr,// instruction address input
    output wire is_stall,		// stall signal
    // output wire is_set_pc,		// set pc signal
    output wire next_PC,
    // if stall, the insFetcher won't fetch the next instruction, and the instruction will be fetched again in the next cycle
    // else insFetcher will fetch the next instruction by the next_PC

    // interaction with RF
    // the RF should return the information after the rob update, because the rob has already deleted that instruction
    input wire [31:0]               rs1_val,
    input wire [31:0]               rs2_val,
    input wire                      rs1_has_dep,
    input wire                      rs2_has_dep,
    input wire [`ROB_SIZE_BIT-1:0]   rs1_dep,
    input wire [`ROB_SIZE_BIT-1:0]   rs2_dep,
    output wire [4:0]               rs1_id,
    output wire [4:0]               rs2_id,

    // interaction with ROB
    //FROM
    output wire [`ROB_SIZE_BIT-1:0] rob_qry1_id,
    input wire                      rob_qry1_fi,
    input wire [31:0]              rob_qry1_value,
    output wire [`ROB_SIZE_BIT-1:0]  rob_qry2_id,
    input wire                      rob_qry2_fi,
    input wire [31:0]              rob_qry2_value, 
    //the ROB should return the result updated by cd_bus' data of the cur cycle 

    //TO
    input wire                      rob_full,		// ROB full signal
    input wire                      rob_clear,		// clear the ROB
    input wire [`ROB_SIZE_BIT-1:0]  rob_vacant_id,  // the ROB id of the instruction
    output reg                     rob_input,      // the input signal of ROB
    output reg                     rob_fi,         // is the instruction has finished, like lui
    output reg [31:0]              rob_value,      // in case that the ins is a lui etc.
    output reg [31:0]              rob_addr,       // the address of the instruction, for restarting ROB
    output reg [`ROB_TYPE_BIT-1:0]  rob_type,       // the type of the instruction
    output reg [4:0]               rob_reg_id,     // the reg id of the instruction



    // interaction with RS
    input wire                      rs_full,	    // RS full signal
    output reg                      rs_input,       // the input signal of RS
    output reg [`RS_TYPE_BIT-1:0]  rs_type,        // the type of the instruction
    output wire [31:0]              rs_r1_val,      
    output wire [31:0]              rs_r2_val,
    output wire                     rs_r1_has_dep,
    output wire                     rs_r2_has_dep,
    output wire [`ROB_SIZE_BIT-1:0]  rs_r1_dep,
    output wire [`ROB_SIZE_BIT-1:0]  rs_r2_dep,
    output wire [`ROB_SIZE_BIT-1:0]  rs_rob_id,
    // output wire [31:0]              rs_imm,
    // output wire [4:0]               rs_rd_id,


    // interaction with LSB
    input wire                      lsb_full,		// LSB full signal
    output reg                      lsb_input,      // the input signal of LSB
    output reg [`LSB_TYPE_BIT-1:0]  lsb_type,       // the type of the instruction
    output wire [31:0]              lsb_r1_val,      
    output wire [31:0]              lsb_r2_val,
    output wire                     lsb_r1_has_dep,
    output wire                     lsb_r2_has_dep,
    output wire [`ROB_SIZE_BIT-1:0]  lsb_r1_dep,
    output wire [`ROB_SIZE_BIT-1:0]  lsb_r2_dep,
    output wire [31:0]              lsb_imm,
    output wire [`ROB_SIZE_BIT-1:0]  lsb_rob_id
    // output wire [4:0]               lsb_rd_id



);
//the instruction decoding this cycle is to be issued next cycle
/**
    1. decode
    2. query RF and ROB for information
    3. issue for the next cycle 
    */

    reg [31:0] r1_val;
    reg [31:0] r2_val;
    reg r1_has_dep;
    reg r2_has_dep;
    reg [`ROB_SIZE_BIT-1:0] r1_dep;  
    reg [`ROB_SIZE_BIT-1:0] r2_dep;
    reg [31:0] imm;
    reg [`ROB_SIZE_BIT-1:0] rob_id;

    assign rs_r1_val = r1_val;
    assign rs_r2_val = rob_type == `ROB_REGI ? imm : r2_val;
    assign rs_r1_has_dep = r1_has_dep;
    assign rs_r2_has_dep = r2_has_dep;
    assign rs_r1_dep = r1_dep;
    assign rs_r2_dep = r2_dep;
    // assign rs_imm = imm;
    assign rs_rob_id = rob_id;
    assign lsb_r1_val = r1_val;
    assign lsb_r2_val = r2_val;
    assign lsb_r1_has_dep = r1_has_dep;
    assign lsb_r2_has_dep = r2_has_dep;
    assign lsb_r1_dep = r1_dep;
    assign lsb_r2_dep = r2_dep;
    assign lsb_rob_id = rob_id;
    assign lsb_imm = imm;

    wire [6:0] opcode = inst[6:0];
    wire [4:0] rd = opcode != BR ? inst[11:7] : {{4{1'b0}} , br_pred};
    wire [4:0] rs1 = inst[19:15];
    wire [4:0] rs2 = inst[24:20];
    wire [2:0] func3 = inst[14:12];
    wire [6:0] func7 = inst[31:25];
    wire [11:0] immI = inst[31:20];
    wire [4:0] immI_star = inst[24:20];
    wire [11:0] immS = {inst[31:25], inst[11:7]};
    wire [12:0] immB = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    wire [32:0] immU = {inst[31:12], 12'b0};
    wire [20:0] immJ = {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

    localparam BR = 7'b1100011;
    localparam JALR = 7'b1100111;
    localparam JAL = 7'b1101111;
    localparam AUIPC = 7'b0010111;
    localparam LUI = 7'b0110111;
    localparam LOAD = 7'b0000011;
    localparam STORE = 7'b0100011;
    localparam ARITH = 7'b0110011; //R
    localparam ARITHI = 7'b0010011; //
    wire is_arithi_star = opcode == ARITHI && (func3 == 3'b001 || func3 == 3'b101);

    // interaction with the insFetcher
    wire need_set_PC = opcode == JAL || opcode == JALR || opcode == BR;
    wire next_PC_JAL = inst_addr + {{11{immJ[20]}}, immJ};
    wire next_PC_JALR = tmp_r1_val + {{20{immI[11]}}, immI};

    wire br_pred = 1;
    wire next_PC_BR = br_pred ?  inst_addr + {{19{immB[12]}}, immB} :inst_addr + 4 ;


    // wire br_pred = br_predictor(); has not finished yet

    assign is_stall = !inst_input || rob_clear || rob_full || rs_full || lsb_full || (opcode == JALR && tmp_r1_has_dep);
    assign next_PC = need_set_PC ? (opcode == JAL ? next_PC_JAL : (opcode == BR ? next_PC_BR : next_PC_JALR)) : inst_addr + 4;
    


    // fetch the information from RF & ROB  
    wire need_r1 = opcode == ARITH || opcode == ARITHI || opcode == LOAD || opcode == STORE || opcode == BR ;
    wire need_r2 = opcode == ARITH || opcode == STORE || opcode == BR;

    wire need_rob = is_stall;
    wire need_rs = opcode == ARITH || opcode == ARITHI || opcode == BR  || opcode == JAL || opcode == JALR;
    wire need_lsb = opcode == LOAD || opcode == STORE;
    wire tmp_r1_val;
    wire tmp_r2_val;

    assign rs1_id = rs1;
    assign rob_qry1_id = rs1_dep;
    assign tmp_r1_has_dep = need_r1 ? (rs1_has_dep ? (rob_qry1_fi ? 0 : 1): 0) : 0;
    assign tmp_r1_dep = rs1_has_dep ? (rob_qry1_fi ? 0 : rs1_dep) : 0;
    // assign tmp_r1_val = rs1_has_dep ? (rob_qry1_value) : rs1_val;
    assign tmp_r1_val = rs1_has_dep ? (rob_qry1_fi ? rob_qry1_value : 0) : rs1_val;
    
    assign rs2_id = rs2;
    assign rob_qry2_id = rs2_dep;
    assign tmp_r2_has_dep = need_r2 ? (rs2_has_dep ? (rob_qry2_fi ? 0 : 1): 0) : 0;
    assign tmp_r2_dep = rs2_has_dep ? (rob_qry2_fi ? 0 : rs2_dep) : 0;
    // assign tmp_r2_val = rs2_has_dep ? (rob_qry2_value) : rs2_val;
    assign tmp_r2_val = rs2_has_dep ? (rob_qry2_fi ? rob_qry2_value : 0) : rs2_val;
    
    // tell rob information to puhs 
    wire tmp_rob_fi = opcode == AUIPC || opcode == LUI || opcode == JAL || opcode == JALR;

always @(posedge clk_in or posedge rst_in) 
begin
    if (rst_in || is_stall) begin
        //reset 
        rs_input <= 0;
        lsb_input <= 0;
        rob_input <= 0;
        r1_val <= 0;
        r2_val <= 0;
        r1_has_dep <= 0;
        r2_has_dep <= 0;
        r1_dep <= 0;
        r2_dep <= 0;
        rob_id <= 0;
    end
    else if (rdy_in) 
    begin
        if(rob_clear)
        begin
            rs_input <= 0;
            lsb_input <= 0;
            rob_input <= 0;
            r1_val <= 0;
            r2_val <= 0;
            r1_has_dep <= 0;
            r2_has_dep <= 0;
            r1_dep <= 0;
            r2_dep <= 0;
            rob_id <= 0;
        end
        else
        begin
            rob_fi <= tmp_rob_fi;
            rob_id <= rob_vacant_id;
            // rob_addr <= inst_addr;
            if(opcode == BR) begin
                // the reverse of the br_pred
                if(br_pred) begin
                    rob_addr <= inst_addr + 4;
                end
                else begin
                    rob_addr <= inst_addr + {{19{immB[12]}}, immB};
                end
            end
            
            rob_reg_id <= rd;


            r1_has_dep <= tmp_r1_has_dep;
            r2_has_dep <= tmp_r2_has_dep;
            r1_dep <= tmp_r1_dep;
            r2_dep <= tmp_r2_dep;
            rob_input <= need_rob;
            rs_input <= need_rs;
            rs_type[4] <= opcode == BR;
            rs_type[3:1] <= func3;
            rs_type[0] <= (opcode == BR || (opcode == ARITHI && !is_arithi_star)) ? 0 : func7[5];
            // U&J won't be in RS
            lsb_input <= need_lsb;
            lsb_type[3] <= opcode == STORE;
            lsb_type[2:0] <= func3;


            if(need_r1)
                r1_val <= tmp_r1_val;
            if(need_r2)
                r2_val <= tmp_r2_val;
            case(opcode)
                ARITH: begin
                    rob_type <= `ROB_REG;
                    //arithmetic
                end
                ARITHI: begin
                    rob_type <= `ROB_REGI;
                    // imm <= id{20'b0 , immI};
                    imm <= is_arithi_star ? {{27{immI_star[4]}}, immI_star} : {{20{immI[11]}}, immI};
                    //arithmetic immediate
                    r2_val <= {{20{immI[11]}}, immI};
                end
                BR: begin
                    rob_type <= `ROB_BR;
                    //branch
                end
                JALR: begin
                    rob_type <= `ROB_REG;
                    //jump and link register
                    rob_value <= inst_addr + 4;
                end
                JAL: begin
                    rob_type <= `ROB_REG;
                    //jump and link
                    rob_value <= inst_addr + 4;
                end
                AUIPC: begin
                    rob_type <= `ROB_REG;
                    //add upper immediate to pc
                    rob_value <= inst_addr + {immU, 12'b0};
                end
                LUI: begin
                    rob_type <= `ROB_REG;
                    //load upper immediate
                    rob_value <= {immU, 12'b0};
                end
                LOAD: begin
                    rob_type <= `ROB_REG;
                    imm <= {{20{immI[11]}}, immI};
                    //load
                end
                STORE: begin
                    rob_type <= `ROB_ST;
                    imm <= {{20{immS[11]}} , immS};
                    //store
                end
            endcase
        end
    end
end
endmodule