module mux_2_1 #(parameter width = 8)
(
 input wire [width-1 : 0] in0 , in1 ,
 input wire sel ,
 output reg [width-1 : 0] out

) ;

always@ (*)
 begin
   case (sel)
    1'b0 : out = in0 ;
    1'b1 : out = in1 ;
    endcase
 end

endmodule