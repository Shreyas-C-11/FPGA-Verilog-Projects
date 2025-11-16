`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.11.2025 21:00:26
// Design Name: 
// Module Name: comparator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module comparator(
    input  [31:0] a,
    input  [31:0] b,
    output        greater,
    output        lesser,
    output        equal
);
    assign greater = (a > b);
    assign lesser  = (a < b);
    assign equal   = (a == b);
endmodule
