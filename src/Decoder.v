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
    output wire [31:0] next_PC,
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

    wire is_c_inst = !(inst[1:0] == 2'b11);
    wire [15:0] inst_c = inst[15:0];
    wire [1:0] opcode_c = inst_c[1:0];
    wire [2:0] func3_c = inst_c[15:13];
    wire [3:0] func4_c = inst_c[15:12]; 

    wire need_r1_c = (opcode_c == 2'b01 && (func3_c == 3'b100 || func3_c[2:1] == 2'b11)) || opcode_c == 2'b00; 
    wire need_r2_c = (opcode_c == 2'b01) || opcode_c == 2'b00; 

    wire [4:0] rs1_rd = need_r1_c ?{{2'b01},inst_c[9:7]} : inst_c[11:7];
    wire [4:0] rs2_rd = need_r2_c ?{{2'b01},inst_c[4:2]} : inst_c[6:2];
    wire [6:0] imm7 = {inst_c[5],inst_c[12:10],inst_c[6],2'b00}; // lw,sw
    wire [5:0] imm6 = {inst_c[12],inst_c[6:2]}; //CI also for lui
    wire [9:0] imm10sp = {inst_c[12],inst_c[4:3],inst_c[5],inst_c[2],inst_c[6],4'b0000};//addi16sp
    wire [8:0] imm9 = {inst_c[12],inst_c[6:5],inst_c[2],inst_c[11:10],inst_c[4:3],1'b0};//br
    wire [9:0] imm10spn = {inst_c[10:7],inst_c[12:11],inst_c[5],inst_c[6],2'b00};//addi4spn
    wire [11:0] imm12 = {inst_c[12],inst_c[8],inst_c[10:9],inst_c[6],inst_c[7],inst_c[2],inst_c[11],inst_c[5:3],{1'b0}};//li

    wire [7:0] imm8swsp = {inst_c[8:7],inst_c[12:9],2'b00};//swsp
    wire [7:0] imm8lwsp = {inst_c[3:2],inst_c[12],inst_c[6:4],2'b00};//lwsp
    wire with_sp = opcode_c == 2'b00 && func3_c == 3'b000 || opcode_c == 2'b01 && func3_c == 3'b011 || opcode_c == 2'b10 && (func3_c == 3'b010 || func3_c == 3'b110); 


    wire [6:0] opcode = inst[6:0];
    wire [4:0] rd = !is_c_inst ? (opcode != BR ? inst[11:7] : {{4{1'b0}} , br_pred}) : (opcode_c == 2'b01 && func3_c[2:1] == 2'b11 ? {{4'b0} , br_pred} : (opcode_c == 2'b00 ? rs2_rd : rs1_rd));
    wire [4:0] rs1 = !is_c_inst ? inst[19:15] : (with_sp ? 5'b00010 : (opcode_c==2'b01 && func3_c == 3'b010 || opcode_c == 2'b10 && func4_c == 4'b1000 && inst_c[6:2] != 0? 5'b00000 : rs1_rd)); //handle the li and mv
    wire [4:0] rs2 = !is_c_inst ? inst[24:20] : rs2_rd;
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
    localparam ARITH = 7'b0110011; 
    localparam ARITHI = 7'b0010011; 
    wire is_arithi_star = !is_c_inst ? opcode == ARITHI && (func3 == 3'b001 || func3 == 3'b101) : 0;

    // interaction with the insFetcher
    wire need_set_PC = !is_c_inst ? opcode == JAL || opcode == JALR || opcode == BR : opcode_c == 2'b10 && func3_c == 3'b100 && inst_c[6:2] == 0 || opcode_c == 2'b01 && (func3_c == 3'b101 || func3_c == 3'b001 || func3_c[2:1] == 2'b11);
    wire [31:0] next_PC_JAL = !is_c_inst ? inst_addr + {{11{immJ[20]}}, immJ} : inst_addr + {{20{imm12[11]}}, imm12}; // also j
    wire [31:0] next_PC_JALR = !is_c_inst ? tmp_r1_val + {{20{immI[11]}}, immI} : tmp_r1_val;
    wire br_pred = 1;
    wire [31:0] next_PC_BR = !is_c_inst ? (br_pred ?  inst_addr + {{19{immB[12]}}, immB} :inst_addr + 4) : (br_pred ? inst_addr + {{23{imm9[8]}}, imm9} : inst_addr + 2);


    // wire br_pred = br_predictor(); has not finished yet

    assign is_stall = !inst_input || rob_clear || rob_full || rs_full || lsb_full || (is_jalr && tmp_r1_has_dep);
    assign next_PC = need_set_PC ? (is_jal ? next_PC_JAL : (is_br ? next_PC_BR : next_PC_JALR)) : (!is_c_inst ? inst_addr + 4 : inst_addr + 2);
    wire is_jal = !is_c_inst ? opcode == JAL : opcode_c == 2'b01 && func3_c[1:0] == 2'b01;
    wire is_jalr = !is_c_inst ? opcode == JALR : opcode_c == 2'b10 && func3_c == 3'b100 && inst_c[6:2] == 0;    
    wire is_br = !is_c_inst ? opcode == BR : opcode_c == 2'b01 && func3_c[2:1] == 2'b11;
    wire is_ld = !is_c_inst ? opcode == LOAD : opcode_c == 2'b00 && func3_c == 3'b010 || opcode_c == 2'b10 && func3_c == 3'b010;
    wire is_st = !is_c_inst ? opcode == STORE : opcode_c == 2'b00 && func3_c == 3'b110 || opcode_c == 2'b10 && func3_c == 3'b110;
    wire is_arithi = !is_c_inst ? opcode == ARITHI : (opcode_c == 2'b01 && (func3_c == 3'b011 && inst_c[11:7] == 5'b00010 || func3_c == 3'b100 && inst_c[11:10] != 2'b11 || func3_c == 3'b010) || func3_c == 3'b000);
    wire is_arith = !is_c_inst ? opcode == ARITH : (opcode_c == 2'b01 && func3_c == 3'b100 && inst_c[11:10] == 2'b11 || opcode_c == 2'b10 && func3_c == 3'b100 && inst_c[6:2] != 0);
    wire is_lui = !is_c_inst ? opcode == LUI : opcode_c == 2'b01 && func3_c == 3'b011 && inst_c[11:7] != 5'b00010;
    wire is_auipc = !is_c_inst ? opcode == AUIPC : 0;
    // fetch the information from RF & ROB  
    wire need_r1 = !is_c_inst ? 1 : 1;
    // wire need_r2 = opcode == ARITH || opcode == STORE || opcode == BR;
    wire need_r2 = !is_arithi && !(is_c_inst && is_br);// the r2 will be 0, store into the imm

    wire need_rob = !is_stall;
    wire need_rs = !is_c_inst ? opcode == ARITH || opcode == ARITHI || opcode == BR : !(opcode_c == 2'b00 && func3_c != 0 || opcode_c == 2'b10 && func3_c[1:0] == 2'b10) && !is_jal && !is_jalr;
    wire need_lsb = is_ld || is_st;
    wire [31:0] tmp_r1_val;
    wire [31:0] tmp_r2_val;
    wire [4:0]tot = is_jal+is_jalr+is_br+is_ld+is_st+is_arith+is_arithi+is_lui+is_auipc; 
    assign rs1_id = rs1;
    assign rob_qry1_id = rs1_dep;
    assign tmp_r1_has_dep = need_r1 ? (rs1_has_dep ? (rob_qry1_fi ? 0 : 1): 0) : 0;
    wire [`ROB_SIZE_BIT-1:0] tmp_r1_dep = rs1_has_dep ? (rob_qry1_fi ? 0 : rs1_dep) : 0;
    // assign tmp_r1_val = rs1_has_dep ? (rob_qry1_value) : rs1_val;
    assign tmp_r1_val = rs1_has_dep ? (rob_qry1_fi ? rob_qry1_value : 0) : rs1_val;
    
    assign rs2_id = rs2;
    assign rob_qry2_id = rs2_dep;
    assign tmp_r2_has_dep = need_r2 ? (rs2_has_dep ? (rob_qry2_fi ? 0 : 1): 0) : 0;
    wire [`ROB_SIZE_BIT-1:0] tmp_r2_dep = rs2_has_dep ? (rob_qry2_fi ? 0 : rs2_dep) : 0;
    // assign tmp_r2_val = rs2_has_dep ? (rob_qry2_value) : rs2_val;
    assign tmp_r2_val = rs2_has_dep ? (rob_qry2_fi ? rob_qry2_value : 0) : rs2_val;
    
    // tell rob information to puhs 
    wire tmp_rob_fi = is_auipc || is_lui || is_jal || is_jalr;
    reg [31:0] cnt;
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
        cnt <= rst_in ? 0 : cnt;
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
            if(tot==0 && !is_stall)begin
                $display("Error: multiple type in one cycle");
                $display("%d %h %h %d", cnt , inst_addr, inst, need_rs);

            end
            // if (inst_input && inst_addr == 32'h188) begin
            //     $display("arrive 188\n");
            // end
            // if (inst_input && inst_addr == 32'h1F4) begin
            //     $display("arrive 1f4\n");
            // end
            if (cnt <= 1000) begin
                cnt <= cnt + 1;
                // // if(inst_addr == 32'h1da)
                // $display("%d %h %h", cnt , inst_addr, inst);
                // if(inst_addr == 0)
                //     $display("arrive 0\n");
            end
            
            rob_fi <= tmp_rob_fi;
            rob_id <= rob_vacant_id;
            // rob_addr <= inst_addr;
            if(is_br) begin
                // the reverse of the br_pred
                if(br_pred) begin
                    rob_addr <= !is_c_inst ? inst_addr + 4 : inst_addr + 2;
                end
                else begin
                    rob_addr <= !is_c_inst ? inst_addr + {{19{immB[12]}}, immB} : {{23{imm9[8]}}, imm9};
                end
            end
            if(is_c_inst) begin
                if(opcode_c == 2'b10 && func3_c == 3'b100 && inst_c[6:2] == 0) begin
                    rob_reg_id <= {{4'b0},inst_c[12]};
                end
                else if(opcode_c == 2'b01 && func3_c[1:0] == 2'b01) begin
                    rob_reg_id <= {{4'b0},~func3_c[2]};
                end
                else begin
                    rob_reg_id <= rd;
                end
            end
            else begin
                rob_reg_id <= rd;
            end 
            
            r1_has_dep <= tmp_r1_has_dep;
            r2_has_dep <= tmp_r2_has_dep;
            r1_dep <= tmp_r1_dep;
            r2_dep <= tmp_r2_dep;
            rob_input <= need_rob;
            rs_input <= need_rs;
            //!!!need to be modified
            if(is_c_inst) begin
                if(is_jal || is_jalr || is_lui) begin
                    rob_value <= is_lui ? {{14{imm6[5]}},imm6,{12'b0}} : inst_addr + 2;
                end
                if(is_ld || is_st || is_br) begin
                    // here should handle the imm of load and 
                    // br do nothing
                    if(is_ld)begin 
                        imm <= with_sp ? imm8lwsp : imm7;
                    end
                    else if(is_st)begin
                        imm <= with_sp ? imm8swsp : imm7;
                    end 
                    else begin
                        imm <= 0; // br
                        rs_type[3:0] <= inst_c[13] ? 4'b0010 : 4'b0000; // bnez beqz
                    end
                end
                else if(opcode_c == 2'b00 || opcode_c == 2'b10 && func3_c == 3'b100 || opcode_c == 2'b01 && (func3_c == 0 || func3_c == 3'b010 || func3_c == 3'b011)) begin
                    rs_type[3:0] <= 4'b0000;//add //li -> addi
                    imm <= opcode_c == 2'b01 ? (with_sp ? {{22{imm10sp[9]}},imm10sp}:{{26{imm6[5]}},imm6}) : imm10spn;
                end
                else if(opcode_c == 2'b10 && func3_c == 3'b000) begin
                    rs_type[3:0] <= 4'b0010;//slli
                    imm <= imm6 == 0 ? 64 : imm6;
                end
                else if(func3_c == 3'b100)begin
                    if(inst_c[11:10] == 2'b11) begin
                        case(inst_c[6:5])
                            2'b00: begin
                                rs_type[3:0] <= 4'b0001;//sub                     
                            end
                            2'b01: begin
                                rs_type[3:0] <= 4'b1000;//xor             
                            end
                            2'b10: begin
                                rs_type[3:0] <= 4'b1100;//or
                            end
                            2'b11: begin
                                rs_type[3:0] <= 4'b1110;//and
                            end
                        endcase
                    end
                    else begin
                        imm[5:0] <= imm6;
                        imm[31:6] <= inst_c[11:10] == 2'b10 ? {26{imm6[5]}} : 0;
                        case(inst_c[11:10]) 
                            2'b00: begin
                                rs_type[3:0] <= 4'b1010;//srli
                            end
                            2'b01: begin
                                rs_type[3:0] <= 4'b1011;//srai
                            end
                            2'b10: begin
                                rs_type[3:0] <= 4'b0000;//andi
                            end
                        endcase
                    end
                end
                lsb_type[2:0] <= 3'b010;
            end
            else begin
                rs_type[3:1] <= func3;
                rs_type[0] <= (opcode == BR || (opcode == ARITHI && !is_arithi_star)) ? 0 : func7[5];
                lsb_type[2:0] <= func3;
                case(opcode)
                    ARITHI: 
                        imm <= is_arithi_star ? {{27{immI_star[4]}}, immI_star} : {{20{immI[11]}}, immI};
                        // r2_val <= {{20{immI[11]}}, immI}; of no use
                    JALR:
                        rob_value <= inst_addr + 4;
                    JAL:
                        rob_value <= inst_addr + 4;
                    AUIPC:
                        rob_value <= inst_addr + immU;
                    LUI:
                        rob_value <= immU;
                    LOAD:
                        imm <= {{20{immI[11]}}, immI};
                    STORE:
                        imm <= {{20{immS[11]}} , immS};
                endcase
            end
            rs_type[4] <= is_br;
            // U&J won't be in RS
            lsb_input <= need_lsb;
            lsb_type[3] <= is_st;
            
            if(need_r1)
                r1_val <= tmp_r1_val;
            if(need_r2)
                r2_val <= tmp_r2_val;
            if(is_arith || is_jal || is_jalr || is_auipc || is_ld || is_lui)
                rob_type <= `ROB_REG;
            if(is_arithi)
                rob_type <= `ROB_REGI;
            if(is_br)
                rob_type <= `ROB_BR;
            if(is_st)
                rob_type <= `ROB_ST;
            
            // case(opcode)
            //     ARITH: begin
            //         rob_type <= `ROB_REG;
            //         //arithmetic
            //     end
            //     ARITHI: begin
            //         rob_type <= `ROB_REGI;
            //         // imm <= id{20'b0 , immI};
            //         imm <= is_arithi_star ? {{27{immI_star[4]}}, immI_star} : {{20{immI[11]}}, immI};
            //         //arithmetic immediate
            //         r2_val <= {{20{immI[11]}}, immI};
            //     end
            //     BR: begin
            //         rob_type <= `ROB_BR;
            //         //branch
            //     end
            //     JALR: begin
            //         rob_type <= `ROB_REG;
            //         //jump and link register
            //         rob_value <= inst_addr + 4;
            //     end
            //     JAL: begin
            //         rob_type <= `ROB_REG;
            //         //jump and link
            //         rob_value <= inst_addr + 4;
            //     end
            //     AUIPC: begin
            //         rob_type <= `ROB_REG;
            //         //add upper immediate to pc
            //         rob_value <= inst_addr + immU;
            //     end
            //     LUI: begin
            //         rob_type <= `ROB_REG;
            //         //load upper immediate
            //         rob_value <= immU;
            //     end
            //     LOAD: begin
            //         rob_type <= `ROB_REG;
            //         imm <= {{20{immI[11]}}, immI};
            //         //load
            //     end
            //     STORE: begin
            //         rob_type <= `ROB_ST;
            //         imm <= {{20{immS[11]}} , immS};
            //         //store
            //     end
            // endcase
        end 
    end
end
endmodule