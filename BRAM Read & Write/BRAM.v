`timescale 1ns / 1ps

// This module reads data from RAM_A and RAM_B based on a mode from RAM_F,
// computes a result, and writes the result and a flag back to RAM_B and RAM_F.

module BRAM(
    input  wire clk,
    input  wire rst,
    input  wire start,
    output reg  done,
    output reg [15:0] result
    );

    // FSM State Definitions
    parameter S_IDLE          = 3'd0;
    parameter S_READ_ADDR     = 3'd1;
    parameter S_WAIT_LATENCY  = 3'd2; // Wait for 2-cycle read latency
    parameter S_COMPUTE_WRITE = 3'd3;
    parameter S_INCREMENT     = 3'd4;
    parameter S_DONE          = 3'd5;

    // State registers
    reg [2:0] state, next_state;
    
    // 0-127 counter
    reg [6:0] i_reg;

    // --- RAM_A Signals (16-wide, 128-deep) ---
    wire [15:0] douta_a;
    reg  [6:0]  addra_a; 

    // --- RAM_B Signals (16-wide, 256-deep) ---
    wire [15:0] douta_b;
    reg  [15:0] dina_b;
    reg  [7:0]  addra_b; 
    reg         wea_b;   

    // --- RAM_F Signals (1-wide, 256-deep) ---
    wire [0:0]  douta_f; 
    reg  [0:0]  dina_f;  
    reg  [7:0]  addra_f; 
    reg         wea_f;   
    
    // --- Datapath Signals ---
    reg [16:0] result_ext; // 17-bit to catch carry/borrow
    reg        flag;
    wire       mode;
    wire [15:0] data_a, data_b;

    // Assign read data wires for clarity
    assign data_a = douta_a;
    assign data_b = douta_b;
    assign mode   = douta_f;

    //================================================================
    // FSM - Sequential Logic
    //================================================================
    always @(posedge clk or posedge rst) 
        begin
            if (rst) 
                begin
                    state <= S_IDLE;
                    i_reg <= 7'd0;
                    done  <= 1'b0;
                end 
            else 
                begin
                    state <= next_state;
                    
                    // Increment counter
                    if (state == S_INCREMENT && i_reg != 7'd127) 
                        begin
                            i_reg <= i_reg + 1;
                        end
                    
                    // Reset counter
                    if (state == S_IDLE) 
                        begin
                            i_reg <= 7'd0;
                        end
                    
                    // Set/clear done flag
                    if (state == S_DONE) 
                        begin
                            done <= 1'b1;
                        end 
                    else 
                        begin
                            done <= 1'b0;
                        end
                end
        end

    //================================================================
    // FSM - Combinational Logic & BRAM Control
    //================================================================
    always @* 
        begin
            // Default values
            next_state = state;
            
            // RAM_A (Read-Only)
            addra_a = i_reg;
            
            // RAM_B (Read/Write)
            addra_b = 127 - i_reg; // Default read address
            dina_b  = result;
            wea_b   = 1'b0;
            
            // RAM_F (Read/Write)
            addra_f = i_reg; // Default read address
            dina_f  = flag;
            wea_f   = 1'b0;
    
            case (state)
                S_IDLE: 
                    begin
                        if (start) 
                            begin
                                next_state = S_READ_ADDR;
                            end
                    end
                
                S_READ_ADDR: 
                    begin
                        // Set read addresses
                        addra_a = i_reg;
                        addra_b = 127 - i_reg;
                        addra_f = i_reg;
                        next_state = S_WAIT_LATENCY;
                    end
    
                // Wait for 2-cycle BRAM read latency
                // Cycle 1 of latency
                S_WAIT_LATENCY: 
                    begin
                        next_state = S_COMPUTE_WRITE;
                    end
                
                // Cycle 2 of latency. Data is NOW valid.
                S_COMPUTE_WRITE: 
                    begin
                        // Set write addresses
                        addra_b = 128 + i_reg;
                        addra_f = 128 + i_reg;
                        
                        // Set write enables
                        wea_b = 1'b1;
                        wea_f = 1'b1;
                        
                        // Data to write (result, flag) is connected from datapath
                        next_state = S_INCREMENT;
                    end
                
                S_INCREMENT: 
                    begin
                        if (i_reg == 7'd127) 
                            begin
                                next_state = S_DONE;
                            end 
                        else 
                            begin
                                next_state = S_READ_ADDR; // Loop back
                            end
                    end
                
                S_DONE: 
                begin
                    if (~start) 
                        begin // Wait for start to go low
                            next_state = S_IDLE;
                        end
                end
                
                default: 
                    begin
                        next_state = S_IDLE;
                    end
            endcase
        end
    
    //================================================================
    // Datapath - Combinational Calculation Logic
    //================================================================
    always @* 
        begin
            // Addition: Result[i] = RAM_A[i] + RAM_B[127-i]
            if (mode == 1'b0) 
            begin
                result_ext = {1'b0, data_a} + {1'b0, data_b};
                flag       = result_ext[16]; // Overflow
            end
            // Subtraction: Result[i] = RAM_A[i] - RAM_B[127-i]
            else 
            begin
                result_ext = {1'b0, data_a} - {1'b0, data_b};
                flag       = result_ext[16]; // Underflow (borrow)
            end
            
            result = result_ext[15:0];
        end

    //================================================================
    // BRAM Instantiations
    //================================================================
        
    // RAM_A: 16-bit, 128-deep (Read-Only)
    blk_mem_gen_0 ram_a_inst (
        .clka(clk),
        .wea(1'b0), // Never write
        .addra(addra_a),
        .dina(16'd0),
        .douta(douta_a)
    );

    // RAM_B: 16-bit, 256-deep (Read/Write)
    blk_mem_gen_1 ram_b_inst (
        .clka(clk),
        .wea(wea_b),
        .addra(addra_b),
        .dina(dina_b),
        .douta(douta_b)
    );

    // RAM_F: 1-bit, 256-deep (Read/Write)
    blk_mem_gen_2 ram_f_inst (
        .clka(clk),
        .wea(wea_f),
        .addra(addra_f),
        .dina(dina_f),
        .douta(douta_f)
    );

endmodule