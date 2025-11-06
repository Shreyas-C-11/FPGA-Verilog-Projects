`timescale 1ns / 1ps

module tb;

    

    // Testbench Signals
    reg clk;
    reg rst;
    reg start;
    wire done;
    wire [15:0]result;
    integer i;
    // Instantiate the Design Under Test (DUT)
    BRAM dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .result(result)
    );

    // Clock Generator
    always 
        begin
            clk = ~clk;
            #5;
        end

    // Test Sequence
    initial begin
        // 1. Initialize signals
        clk=1'b0;
        rst   = 1'b1;
        start = 1'b0;
        // 2. Apply Reset
        #20;
        rst = 1'b0;
        #20;
        // 3. Start the process
        $display("Applying start signal...");
        start = 1'b1;
        
        @(posedge clk);
        start = 1'b0;
        
        // 4. Wait for the process to complete
        $display("Waiting for done signal...");
        @(posedge done);
        
        $display("Process finished. Check RAM contents in simulation.");
        
    end

endmodule