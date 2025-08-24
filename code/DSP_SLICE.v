module DSP_SLICE #( 
        parameter width_one = 18 , width_two = 36 , width_three = 48 , RSTTYPE = 1'b0,
        parameter A0REG = 1'b1 , A1REG = 1'b1 , // for deciding either registered or not for input A
        parameter B0REG = 1'b1 , B1REG = 1'b1 , // for deciding either registered or not for input B
        parameter B_INPUT = 1'b0 ,              // for deciding either input B comes from cascading or from normal logic
        parameter CREG = 1'b1   ,             // for deciding either registered or not for input C
        parameter DREG = 1'b1   ,             // for deciding either registered or not for input D
        parameter MREG = 1'b1                 // for deciding either registered or not for multiplier output
)
(
    // Data Input Ports
    input wire [width_one-1:0] A, B, D, 
    input wire [width_three-1:0] C,
    input wire CARRYIN,
    // Control Input Ports
    input wire CLK,
    input wire[7:0] OPMODE,
    // Reset/Clock Enable Input Ports
    input wire CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP,
    input wire RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP,
    // Cascade Input Port
    input wire [width_three-1:0] PCIN,
    input wire [width_one-1:0]   BCIN,
    // Data Output Ports
    output wire CARRYOUT, CARRYOUTF,
    output wire [width_two-1:0] M,
    output wire[width_three-1:0] P,
    // Cascade Output Ports
    output wire [width_one-1:0] BCOUT,
    output wire [width_three-1:0] PCOUT
);

//internal wires
wire signed [width_one-1 : 0] a0_reg , a0_out , a1_reg , a1_out ;
wire signed [width_one-1 : 0] bout_mux , b0_out , b0_reg , b1_reg , b1_out , b_opmode4 ;
wire signed [width_three-1 : 0]  c_reg , c_out ;
wire signed [width_one-1 : 0]    d_reg , d_out ;
wire signed [width_one-1 : 0]  mult_in_a, mult_in_b;
wire signed [width_two-1 : 0]  mult_out;
wire signed [width_one-1 : 0]  preAdd_in_b, preAdd_in_d, preAdd_out;
wire signed [width_three-1 : 0]  postAdd_X, postAdd_Z, postAdd_out;
wire CIN;
// Instantiations
// A : 18-bit data input to the DSP multiplier
//     Can also be used as an input to the post-adder/subtracter by concatenation with B and D
//     depending on the value of OPMODE[1:0]
  
pipeline_reg  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )
        
        a0 (.D_in(A) ,
                .SEL(A0REG) ,
                .CLK(CLK) , 
                .RST(RSTA) , 
                .CE(CEA) , 
                .D_out(a0_out)) ;
  
pipeline_reg  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )
        
        a1 (.D_in(a0_out) , 
                .SEL(A1REG) ,
                .CLK(CLK) , 
                .RST(RSTA) , 
                .CE(CEA) , 
                .D_out(mult_in_a)) ; 

// B : 18-bit data input
//     - Can be used as input to the pre-adder/subtracter
//     - Can be used as input to the multiplier (depending on OPMODE[4])
//     - Can be used as input to the post-adder/subtracter (depending on OPMODE[1:0])
//     - Supports cascading: when BCOUT from an adjacent DSP48A1 slice is used,
//       tools map it to BCIN and configure the B_INPUT attribute

assign bout_mux = (B_INPUT) ? BCIN : B;

pipeline_reg  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )
        
        b0 (.D_in(bout_mux) , 
                .SEL(B0REG) ,
                .CLK(CLK) , 
                .RST(RSTB) , 
                .CE(CEB) , 
                .D_out(preAdd_in_b)) ;  

assign preAdd_out = (OPMODE[6]) ? (preAdd_in_d - preAdd_in_b) : (preAdd_in_d + preAdd_in_b) ;

assign b_opmode4 = (OPMODE[4]) ? preAdd_out : preAdd_in_b;

pipeline_reg  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )

        b1 (.D_in(b_opmode4) , 
                .SEL(B1REG) ,
                .CLK(CLK) , 
                .RST(RSTB) , 
                .CE(CEB) , 
                .D_out(mult_in_b)) ;  

// C : 48-bit data input
//     -Can be used as input to the post-adder/subtracter

pipeline_reg  #(.reg_size(width_three) , 
            .RSTTYPE(RSTTYPE) )
        
        c (.D_in(C) , 
               .SEL(CREG) ,
               .CLK(CLK) , 
               .RST(RSTC) , 
               .CE(CEC) , 
               .D_out(c_out)) ;  

assign mult_out = mult_in_a * mult_in_b ;

pipeline_reg  #(.reg_size(width_two) , 
            .RSTTYPE(RSTTYPE) )
        
        mult_result (.D_in(mult_out) ,
               .SEL(MREG) ,
               .CLK(CLK) ,
               .RST(RSTM) ,
               .CE(CEM) ,
               .D_out(M)) ;

// D : 18-bit data input
//     Functions:
//       • Used as input to the pre-adder/subtracter
//       • Lower 12 bits (D[11:0]) are concatenated with A and B
//         → this concatenated value can optionally be sent to the post-adder/subtracter
//           depending on OPMODE[1:0]

pipeline_reg  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )
        
        d (.D_in(D) ,
               .SEL(DREG) ,
               .CLK(CLK) ,
               .RST(RSTD) ,
               .CE(CED) ,
               .D_out(d_reg)) ;

mux_4_1 #(.width(width_three)) 

        X (.in0(0) , 
               .in1({ {12{M[35]}}, M } ) , 
               .in2({D[11:0],B[17:0],A[17:0]}) , 
               .in3(p) , 
               .sel(OPMODE[1:0]) , 
               .out(postAdd_X)) ;

mux_4_1 #(.width(width_three)) 

        Z (.in0(0) , 
               .in1(PCIN) , 
               .in2(P) , 
               .in3(C) , 
               .sel(OPMODE[3:2]) , 
               .out(postAdd_Z)) ;

assign postAdd_out = (OPMODE[7]) ? (postAdd_Z - (postAdd_X + CIN)) : (postAdd_Z + postAdd_X);

pipeline_reg  #(.reg_size(width_three) , 
            .RSTTYPE(RSTTYPE) )

        postAdd_result (.D_in(postAdd_out) ,
               .SEL(DREG) ,
               .CLK(CLK) ,
               .RST(RSTD) ,
               .CE(CED) ,
               .D_out(P)) ;

endmodule
