module mux_4_1 #( parameter width = 8 )
(
input [width-1 : 0] in0 , in1 , in2 , in3 ,
input sel ,
output reg [width-1 : 0] out 
) ;

always@ (*)
begin
  case (sel)
   2'b00 : out = in0 ;
   2'b01 : out = in1 ;
   2'b10 : out = in2 ;
   2'b11 : out = in3 ;
   endcase
end
endmodule