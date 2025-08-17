module pipeline_reg
#(
    parameter reg_size = 8,
    parameter RSTTYPE = 0 // 0: Asynchronous, 1: Synchronous
)
(
    input[reg_size-1:0] data_in,
    input SEL, // Mux Selection
    input CLKR, // Clock 
    input RSTR, // Reset
    input CER,  // Clock Enable
    output[reg_size-1:0] data_out
);

reg [reg_size-1:0] Reg_data;

assign data_out = (SEL) ? Reg_data : data_in;
generate
    if (RSTTYPE) begin
        if (RSTTYPE == ASYNCH) begin
            always @(posedge CLKR or posedge RSTR) begin
                if (RSTR) 
                    Reg_data <= 0;
                else if (CER)
                    Reg_data <= data_in;
            end
        end else begin
            always @(posedge CLKR) begin
                if (RSTR)
                    Reg_data <= 0;
                else if (CER)
                    Reg_data <= data_in;            
            end
        end
    end 
endgenerate

endmodule