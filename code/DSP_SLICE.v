module DSP_SLICE #( parameter width_one = 18 , width_two = 36 , width_three = 48 , RSTTYPE = 1'b0)
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

//attributes
parameter A0REG = 1'b1 , A1REG = 1'b1 ; // for deciding either registered or not for input A
parameter B0REG = 1'b1 , B1REG = 1'b1 ; // for deciding either registered or not for input B
parameter B_INPUT = 1'b0 ;              // for deciding either input B comes from cascading or from normal logic
parameter CREG = 1'b1   ;             // for deciding either registered or not for input C
parameter DREG = 1'b1   ;             // for deciding either registered or not for input D
//internal wires
wire [width_one-1 : 0] a0_reg , a0_out , a1_reg , a1_out ;
wire [width_one-1 : 0] bout_mux , b0_out , b0_reg , b1_reg , b1_out , b_opmode4 ;
wire [width_three-1 : 0]  c_reg , c_out ;
wire [width_one-1 : 0]    d_reg , d_out ;
// Instantiations
// A : 18-bit data input to the DSP multiplier
//     Can also be used as an input to the post-adder/subtracter by concatenation with B and D
//     depending on the value of OPMODE[1:0]

  
rst_type  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )
        
        rst_a0 (.D_in(A) , 
                .CLK(CLK) , 
                .RST(RSTA) , 
                .CE(CEA) , 
                .Q(a0_reg)) ;

mux_2_1 #(.width(width_one)) 

        mux_a0 (.in0(A) , 
                .in1(a0_reg) , 
                .sel(A0REG) , 
                .out(a0_out)) ;   

rst_type  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )
        
        rst_a1 (.D_in(a0_out) , 
                .CLK(CLK) , 
                .RST(RSTA) , 
                .CE(CEA) , 
                .Q(a1_reg)) ; 

mux_2_1 #(.width(width_one)) 

        mux_a1 (.in0(a0_out) , 
                .in1(a1_reg) , 
                .sel(A1REG) , 
                .out(a1_out)) ;    

// B : 18-bit data input
//     - Can be used as input to the pre-adder/subtracter
//     - Can be used as input to the multiplier (depending on OPMODE[4])
//     - Can be used as input to the post-adder/subtracter (depending on OPMODE[1:0])
//     - Supports cascading: when BCOUT from an adjacent DSP48A1 slice is used,
//       tools map it to BCIN and configure the B_INPUT attribute

mux_2_1 #(.width(width_one)) 

        mux_in_b (.in0(B) , 
                  .in1(BCIN) , 
                  .sel(B_INPUT) , 
                  .out(bout_mux)) ;  

rst_type  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )
        
        rst_b0 (.D_in(bout_mux) , 
                .CLK(CLK) , 
                .RST(RSTB) , 
                .CE(CEB) , 
                .Q(b0_reg)) ;  

mux_2_1 #(.width(width_one)) 

        mux_b0 (.in0(bout_mux) , 
                .in1(b0_reg) , 
                .sel(B0REG) , 
                .out(b0_out)) ;   

rst_type  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )
        
        rst_b1 (.D_in(b_opmode4) , 
                .CLK(CLK) , 
                .RST(RSTB) , 
                .CE(CEB) , 
                .Q(b1_reg)) ;  

mux_2_1 #(.width(width_one)) 

        mux_b1 (.in0(b_opmode4) , 
                .in1(b1_reg) , 
                .sel(B1REG) , 
                .out(b1_out)) ;   


// C : 48-bit data input
//     -Can be used as input to the post-adder/subtracter

rst_type  #(.reg_size(width_three) , 
            .RSTTYPE(RSTTYPE) )
        
        rst_c (.D_in(C) , 
               .CLK(CLK) , 
               .RST(RSTC) , 
               .CE(CEC) , 
               .Q(c_reg)) ;  

mux_2_1 #(.width(width_three)) 

        mux_c (.in0(C) , 
               .in1(c_reg) , 
               .sel(CREG) , 
               .out(c_out)) ;

// D : 18-bit data input
//     Functions:
//       • Used as input to the pre-adder/subtracter
//       • Lower 12 bits (D[11:0]) are concatenated with A and B
//         → this concatenated value can optionally be sent to the post-adder/subtracter
//           depending on OPMODE[1:0]

rst_type  #(.reg_size(width_one) , 
            .RSTTYPE(RSTTYPE) )
        
        rst_d (.D_in(D) , 
               .CLK(CLK) , 
               .RST(RSTD) , 
               .CE(CED) , 
               .Q(d_reg)) ;  

mux_2_1 #(.width(width_one)) 

        mux_d (.in0(D) , 
               .in1(d_reg) , 
               .sel(DREG) , 
               .out(d_out)) ;


endmodule
