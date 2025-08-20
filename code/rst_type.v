// Module: Reset_Selector
// Description: This module allows the user to select between synchronous and asynchronous reset behavior.
module rst_type
#(
    parameter reg_size = 8,
    parameter RSTTYPE = 0 // 0: Asynchronous, 1: Synchronous
)
(
    input wire [reg_size-1:0] D_in,
    input wire CLK, // Clock 
    input wire RST, // Reset
    input wire CE,  // Clock Enable
    output reg [reg_size-1:0] Q
);



generate
    if (RSTTYPE) begin
        if (RSTTYPE == 0) begin
            always @(posedge CLK or posedge RST) begin
                if (RST) 
                    Q <= 0;
                else if (CE)
                    Q <= D_in;
            end
        end else begin
            always @(posedge CLK) begin
                if (RST)
                    Q <= 0;
                else if (CE)
                    Q <= D_in;            
            end
        end
    end 
endgenerate

endmodule