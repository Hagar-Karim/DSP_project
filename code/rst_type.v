// Module: Reset_Selector
// Description: This module allows the user to select between synchronous and asynchronous reset behavior.
module pipeline_reg
#(
    parameter reg_size = 8,
    parameter RSTTYPE = 0 // 0: Asynchronous, 1: Synchronous
)
(
    input wire [reg_size-1:0] D_in,
    input wire SEL, // Mux Selection
    input wire CLK, // Clock 
    input wire RST, // Reset
    input wire CE,  // Clock Enable
    output wire [reg_size-1:0] D_out
);


reg [reg_size-1:0] Reg_data;

assign D_out = (SEL) ? Reg_data : D_in;

generate
    if (RSTTYPE) begin
        if (RSTTYPE == 0) begin
            always @(posedge CLK or posedge RST) begin
                if (RST) 
                    Reg_data <= 0;
                else if (CE)
                    Reg_data <= D_in;
            end
        end else begin
            always @(posedge CLK) begin
                if (RST)
                    Reg_data <= 0;
                else if (CE)
                    Reg_data <= D_in;            
            end
        end
    end 
endgenerate

endmodule