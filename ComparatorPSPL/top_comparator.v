module top_comparator(
    input  clk,
    input  resetn
);

    reg [31:0] a;
    reg [31:0] b;
    wire gt, lt, eq;

    // Instantiate comparator
    comparator U1 (
        .a(a),
        .b(b),
        .greater(gt),
        .lesser(lt),
        .equal(eq)
    );
    
    ila_0 U_ILA (
    .clk(clk),
    .probe0(a),
    .probe1(b),
    .probe2({gt, lt, eq})
    );


    // Simple pattern generator
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            a <= 32'd0;
            b <= 32'd100;
        end else begin
            a <= a + 1;
            b <= b - 1;
        end
    end

endmodule
