`include "Config.v"
module RF(
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    // interaction with ROB
    input wire is_update_val,
    input wire [`ROB_SIZE_BIT-1:0]update_val_id;
    input wire [31:0] update_val

    input wire is_update_dep,
    input wire [`ROB_SIZE_BIT-1:0]update_dep_id;
    input wire [`ROB_SIZE_BIT-1:0] update_dep;

    // interaction with Decoder
    input wire is_qry_r1;
    input wire is_qry_r2;
    input wire [4:0] qry_r1_id;
    input wire [4:0] qry_r2_id;
    output wire [31:0] qry_r1_val;
    output wire [31:0] qry_r2_val;
    output wire [`ROB_SIZE_BIT-1:0] qry_r1_dep;
    output wire [`ROB_SIZE_BIT-1:0] qry_r2_dep;
    output wire qry_r1_has_dep;
    output wire qry_r2_has_dep;

);
//


endmodule