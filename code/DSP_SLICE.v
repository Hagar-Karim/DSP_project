module DSP_SLICE
(
    // Data Input Ports 
    input[17:0] A, B, D,
    input[47:0] C,
    input CARRYIN,
    // Control Input Ports
    input CLK,
    input[7:0] OPMODE,
    // Reset/Clock Enable Input Ports
    input CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP,
    input RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP,
    // Cascade Input Port
    input[47:0] PCIN,
    // Data Output Ports
    output CARRYOUT, CARRYOUTF,
    output[35:0] M,
    output[47:0] P,
    // Cascade Output Ports
    output[17:0] BCOUT,
    output[47:0] PCOUT
);

// Instantiations

endmodule