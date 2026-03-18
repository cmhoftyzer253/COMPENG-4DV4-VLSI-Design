`timescale 1ns/100ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define RST_DELAY   2
`define MAX_CYCLE   120000

// ============================================================
//  Debug testbench for MiniProject-02 Simple MIPS CPU
//
//  Store in: 00_TESTBED/testbed_temp.v
//
//  Run from 01_RTL:
//    xmverilog ../00_TESTBED/testbed_temp.v ../00_TESTBED/define.v ../00_TESTBED/inst_mem.vp ../00_TESTBED/data_mem.vp core.v alu.v register_file.v +access+rw +define+P0
//
//  Change +define+P0 to +define+P1, +define+P2, etc.
// ============================================================

`ifdef P0
    `define INST_FILE "../00_TESTBED/PATTERN/p0/inst.dat"
    `define DATA_FILE "../00_TESTBED/PATTERN/p0/data.dat"
    `define STAT_FILE "../00_TESTBED/PATTERN/p0/status.dat"
    `define PAT_NAME  "P0"
`elsif P1
    `define INST_FILE "../00_TESTBED/PATTERN/p1/inst.dat"
    `define DATA_FILE "../00_TESTBED/PATTERN/p1/data.dat"
    `define STAT_FILE "../00_TESTBED/PATTERN/p1/status.dat"
    `define PAT_NAME  "P1"
`elsif P2
    `define INST_FILE "../00_TESTBED/PATTERN/p2/inst.dat"
    `define DATA_FILE "../00_TESTBED/PATTERN/p2/data.dat"
    `define STAT_FILE "../00_TESTBED/PATTERN/p2/status.dat"
    `define PAT_NAME  "P2"
`elsif P3
    `define INST_FILE "../00_TESTBED/PATTERN/p3/inst.dat"
    `define DATA_FILE "../00_TESTBED/PATTERN/p3/data.dat"
    `define STAT_FILE "../00_TESTBED/PATTERN/p3/status.dat"
    `define PAT_NAME  "P3"
`elsif P4
    `define INST_FILE "../00_TESTBED/PATTERN/p4/inst.dat"
    `define DATA_FILE "../00_TESTBED/PATTERN/p4/data.dat"
    `define STAT_FILE "../00_TESTBED/PATTERN/p4/status.dat"
    `define PAT_NAME  "P4"
`else
    `define INST_FILE "../00_TESTBED/PATTERN/p0/inst.dat"
    `define DATA_FILE "../00_TESTBED/PATTERN/p0/data.dat"
    `define STAT_FILE "../00_TESTBED/PATTERN/p0/status.dat"
    `define PAT_NAME  "P0 (default)"
`endif

module testbed;

    reg             i_clk;
    reg             i_rst_n;

    wire [31:0]     o_i_addr;
    wire [31:0]     i_i_inst;

    wire            o_d_wen;
    wire [31:0]     o_d_addr;
    wire [31:0]     o_d_wdata;
    wire [31:0]     i_d_rdata;

    wire [1:0]      o_status;
    wire            o_status_valid;

    reg [1:0]       golden_status [0:1023];
    reg [31:0]      golden_data [0:63];

    integer         status_count;
    integer         error_count;
    integer         total_status;
    integer         i;

    // Load instruction memory into the protected module
    initial $readmemb(`INST_FILE, u_inst_mem.mem_r);

    // Opcode name lookup for debug prints
    function [8*8-1:0] opcode_name;
        input [5:0] op;
        case (op)
            6'd1:    opcode_name = "add     ";
            6'd2:    opcode_name = "sub     ";
            6'd3:    opcode_name = "addi    ";
            6'd4:    opcode_name = "lw      ";
            6'd5:    opcode_name = "sw      ";
            6'd6:    opcode_name = "and     ";
            6'd7:    opcode_name = "or      ";
            6'd8:    opcode_name = "nor     ";
            6'd9:    opcode_name = "beq     ";
            6'd10:   opcode_name = "bne     ";
            6'd11:   opcode_name = "slt     ";
            6'd12:   opcode_name = "eof     ";
            default: opcode_name = "UNKNOWN ";
        endcase
    endfunction

    // ------ Instantiate Core ------
    core u_core (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .o_i_addr       (o_i_addr),
        .i_i_inst       (i_i_inst),
        .o_d_wen        (o_d_wen),
        .o_d_addr       (o_d_addr),
        .o_d_wdata      (o_d_wdata),
        .i_d_rdata      (i_d_rdata),
        .o_status       (o_status),
        .o_status_valid (o_status_valid)
    );

    // ------ Instantiate Protected Instruction Memory ------
    inst_mem u_inst_mem (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .i_addr         (o_i_addr),
        .o_inst         (i_i_inst)
    );

    // ------ Instantiate Protected Data Memory ------
    data_mem u_data_mem (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .i_wen          (o_d_wen),
        .i_addr         (o_d_addr),
        .i_wdata        (o_d_wdata),
        .o_rdata        (i_d_rdata)
    );

    // ------ Clock generation ------
    initial i_clk = 0;
    always #(`CYCLE/2.0) i_clk = ~i_clk;

    // ------ VCD dump ------
    initial begin
        $dumpfile("tb_debug.vcd");
        $dumpvars(0, testbed);
    end

    // ------ Load golden data ------
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            golden_status[i] = 2'd0;
        for (i = 0; i < 64; i = i + 1)
            golden_data[i] = 32'd0;

        $readmemb(`STAT_FILE, golden_status);
        $readmemh(`DATA_FILE, golden_data);
    end

    // ------ Count total expected status entries ------
    initial begin
        total_status = 0;
        #1;
        for (i = 0; i < 1024; i = i + 1) begin
            total_status = total_status + 1;
            if (golden_status[i] == 2'd3 || golden_status[i] == 2'd2)
                i = 1024;
        end
        $display("============================================================");
        $display("  Debug Testbench - MiniProject 02 - Simple MIPS CPU");
        $display("  Pattern: %s  (%s)", `PAT_NAME, `INST_FILE);
        $display("  Total expected instructions: %0d", total_status);
        $display("============================================================");
    end

    // ------ Reset ------
    initial begin
        i_rst_n = 1;
        #(0.25 * `CYCLE);
        i_rst_n = 0;
        #(`RST_DELAY * `CYCLE);
        i_rst_n = 1;
    end

    // ------ Monitor status outputs ------
    initial begin
        status_count = 0;
        error_count  = 0;

        @(posedge i_rst_n);

        forever begin
            @(posedge i_clk);
            #(0.1);

            if (o_status_valid) begin
                $display("------- Instruction %0d -------", status_count);
                $display("  Time        : %0t ns", $time);
                $display("  PC (addr)   : %0d (0x%08h)", o_i_addr, o_i_addr);
                $display("  Instruction : 0x%08h", i_i_inst);
                $display("  Opcode_q    : %0d (%0s)", u_core.opcode_q, opcode_name(u_core.opcode_q));
                $display("  i_inst_q=%0b  r_inst_q=%0b  branch_inst_q=%0b",
                         u_core.i_inst_q, u_core.r_inst_q, u_core.branch_inst_q);
                $display("  s1_q=%0d  imm_q=%0d", u_core.s1_q, u_core.imm_q);
                $display("  RF_A data_q : %0d (0x%08h)", u_core.rf_a_rd_data_q, u_core.rf_a_rd_data_q);
                $display("  RF_B data_q : %0d (0x%08h)", u_core.rf_b_rd_data_q, u_core.rf_b_rd_data_q);
                $display("  ALU result_q: %0d (0x%08h)", u_core.alu_res_q, u_core.alu_res_q);
                $display("  Branch taken: %0b", u_core.branch_taken_q);
                $display("  Overflow_q  : %0b", u_core.overflow_q);
                $display("  D_WEN=%0b  D_ADDR=0x%08h  D_WDATA=0x%08h", o_d_wen, o_d_addr, o_d_wdata);
                $display("  o_status=%0d  o_status_valid=%0b", o_status, o_status_valid);

                if (status_count < 1024) begin
                    if (o_status !== golden_status[status_count]) begin
                        $display("  >>> STATUS ERROR! Golden=%0d  Yours=%0d <<<",
                                 golden_status[status_count], o_status);
                        error_count = error_count + 1;
                    end else begin
                        $display("  Status CORRECT (%0d)", o_status);
                    end
                end

                status_count = status_count + 1;

                // Stop on EOF or overflow
                if (o_status == 2'd3 || o_status == 2'd2) begin
                    $display("");
                    $display("============================================================");
                    $display("  CPU stopped: status = %0d (%s)", o_status,
                             (o_status == 2'd3) ? "EOF" : "OVERFLOW");
                    $display("  Total instructions executed: %0d", status_count);
                    $display("============================================================");

                    $display("");
                    if (error_count == 0)
                        $display(">>> ALL STATUS CHECKS PASSED! <<<");
                    else
                        $display(">>> TOTAL STATUS ERRORS: %0d <<<", error_count);

                    #(5 * `CYCLE);
                    $finish;
                end
            end
        end
    end

    // ------ Timeout ------
    initial begin
        #(`MAX_CYCLE * `CYCLE);
        $display("============================================================");
        $display("  TIMEOUT: Exceeded %0d cycles!", `MAX_CYCLE);
        $display("  Instructions completed: %0d", status_count);
        $display("============================================================");
        $finish;
    end

endmodule
