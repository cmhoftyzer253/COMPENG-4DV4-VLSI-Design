module alu (
    input               i_clk,
    input               i_rst_n,
    input               i_valid,
    input signed [11:0] i_data_a,
    input signed [11:0] i_data_b,
    input        [2:0]  i_inst,
    output              o_valid,
    output       [11:0] o_data,
    output              o_overflow
);
    
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg [11:0]          o_data_w, o_data_r;
reg                 o_valid_w, o_valid_r;
reg                 o_overflow_w, o_overflow_r;

// ---- Add your own wires and registers here if needed ---- //
reg                 valid;
reg signed [11:0]   data_a;
reg signed [11:0]   data_b;
reg [2:0]           inst;

reg                 mac_ff;
reg signed [11:0]   mac_sum_ff;
reg                 mac_overflow_ff;

reg signed [23:0]   prod_long;
reg signed [23:0]   prod_long_round;
reg signed [11:0]   prod;
reg                 mul_overflow;

reg                 mac_active;
reg signed [11:0]   mac_operand_ctrl;
reg signed [11:0]   mul_data;
reg                 mac_sum_overflow;
reg                 mac_overflow;

reg                 sub;
reg signed [11:0]   data_b_ctrl;
reg signed [11:0]   add_sub_data;
reg                 add_sub_overflow;

reg [11:0]          xnor_data;
reg signed [11:0]   relu_data;

reg signed [12:0]   sum_long;
reg signed [12:0]   mean_long;
reg [11:0]          mean_data;

reg [11:0]          abs_data_a;
reg [11:0]          abs_data_b;
reg [11:0]          abs_max_data;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_valid          = o_valid_r;
assign o_data           = o_data_r;
assign o_overflow       = o_overflow_r;
// ---- Add your own wire data assignments here if needed ---- //

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
always@(*) begin

    //multiply
    prod_long           =   data_a * data_b;
    prod_long_round     =   prod_long + (prod_long[23] ? 24'sd15 : 24'sd16);
    prod                =   prod_long_round[16:5];
    mul_overflow        =   prod_long_round[23:16] != {8{prod_long_round[16]}};

    //mac accumulate
    mac_active          =   mac_ff & (inst == 3'b011);
    mac_operand_ctrl    =   mac_active ? mac_sum_ff : 12'b0;
    mul_data            =   mac_operand_ctrl + prod;
    mac_sum_overflow    =   ((mac_operand_ctrl[11] == prod[11]) & (mul_data[11] != mac_operand_ctrl[11]));
    mac_overflow        =   mul_overflow | mac_sum_overflow | mac_overflow_ff;

    //add/subtract
    sub                 =   (inst == 3'b001);
    data_b_ctrl         =   sub ? (~data_b + 12'd1) : data_b;

    add_sub_data        =   data_a + data_b_ctrl;
    add_sub_overflow    =   sub ?   ((data_a[11] != data_b[11]) & (add_sub_data[11] != data_a[11])) : 
                                    ((data_a[11] == data_b[11]) & (add_sub_data[11] != data_a[11]));

    //xnor
    xnor_data           =   ~(data_a ^ data_b);

    //relu
    relu_data           =   data_a[11] ? 12'd0 : data_a;

    //mean 
    mean_long           =   $signed({data_a[11], data_a}) + $signed({data_b[11], data_b});
    mean_data           =   mean_long[12:1];


    //absolute max
    abs_data_a          =   data_a[11] ? (~data_a + 12'd1) : data_a;
    abs_data_b          =   data_b[11] ? (~data_b + 12'd1) : data_b;

    abs_max_data        =   (abs_data_a > abs_data_b) ? abs_data_a : abs_data_b;

    //default
    o_data_w            =   12'd0;
    o_overflow_w        =   1'b0;
    o_valid_w           =   valid;

    case (inst)
        3'b000, 3'b001: begin
            o_data_w        =   add_sub_data;
            o_overflow_w    =   add_sub_overflow;
        end
        3'b010: begin
            o_data_w        =   mul_data;
            o_overflow_w    =   mul_overflow;
        end
        3'b011: begin
            o_data_w        =   mul_data;
            o_overflow_w    =   mac_overflow;
        end
        3'b100: begin
            o_data_w        =   xnor_data;
            o_overflow_w    =   1'b0;
        end
        3'b101: begin
            o_data_w        =   relu_data;
            o_overflow_w    =   1'b0;
        end
        3'b110: begin
            o_data_w        =   mean_data;
            o_overflow_w    =   1'b0;
        end
        3'b111: begin
            o_data_w        =   abs_max_data;
            o_overflow_w    =   1'b0;
        end
        default: begin
            o_data_w        =   12'h0;
            o_overflow_w    =   1'b0;
        end
    endcase
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------

//mac flip flops
always@(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        mac_ff              <= 1'b0;
        mac_sum_ff          <= 12'h0;
        mac_overflow_ff     <= 1'b0;
    end else if (valid) begin
        if (inst == 3'b011) begin
            mac_ff          <= 1'b1;
            mac_sum_ff      <= mul_data;
            mac_overflow_ff <= mac_overflow;
        end else begin
            mac_ff          <= 1'b0;
            mac_sum_ff      <= 12'h0;
            mac_overflow_ff <= 1'b0;
        end
    end
end

//input flip flops - negative clock edge
always@(negedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        valid               <= 1'b0;
        data_a              <= 12'h0;
        data_b              <= 12'h0;
        inst                <= 3'b0;
    end else begin
        valid               <= i_valid;
        data_a              <= i_data_a;
        data_b              <= i_data_b;
        inst                <= i_inst;
    end
end 

//output flip flops - positive clock edge
always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        o_data_r            <= 0;
        o_overflow_r        <= 0;
        o_valid_r           <= 0;
    end else begin
        o_data_r            <= o_data_w;
        o_overflow_r        <= o_overflow_w;
        o_valid_r           <= o_valid_w;
    end
end


endmodule
