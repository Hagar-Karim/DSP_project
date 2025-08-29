`timescale 1ns/1ps

module DSP_SLICE_tb;

    localparam W1 = 18, W2 = 36, W3 = 48;

    // DUT inputs
    reg  [W1-1:0] A, B, D;
    reg  [W3-1:0] C;
    reg           CARRYIN;
    reg           CLK, RST;
    reg  [7:0]    OPMODE;

    // Enables / resets
    reg CEA, CEB, CEC, CED, CEM, CEOPMODE, CEP, CECARRYIN;
    reg RSTA, RSTB, RSTC, RSTD, RSTM, RSTOPMODE, RSTP, RSTCARRYIN;

    // Cascade inputs
    reg  [W3-1:0] PCIN;
    reg  [W1-1:0] BCIN;

    // DUT outputs
    wire          CARRYOUT, CARRYOUTF;
    wire [W2-1:0] M;
    wire [W3-1:0] P;
    wire [W1-1:0] BCOUT;
    wire [W3-1:0] PCOUT;

    // Instantiate DUT
    DSP_SLICE dut (
        .A(A), .B(B), .D(D), .C(C), .CARRYIN(CARRYIN),
        .CLK(CLK), .OPMODE(OPMODE),
        .CEA(CEA), .CEB(CEB), .CEC(CEC), .CED(CED), .CEM(CEM),
        .CEOPMODE(CEOPMODE), .CEP(CEP), .CECARRYIN(CECARRYIN),
        .RSTA(RSTA), .RSTB(RSTB), .RSTC(RSTC), .RSTD(RSTD),
        .RSTM(RSTM), .RSTOPMODE(RSTOPMODE), .RSTP(RSTP), .RSTCARRYIN(RSTCARRYIN),
        .PCIN(PCIN), .BCIN(BCIN),
        .CARRYOUT(CARRYOUT), .CARRYOUTF(CARRYOUTF),
        .M(M), .P(P),
        .BCOUT(BCOUT), .PCOUT(PCOUT)
    );

    // Clock
    initial CLK = 0;
    always #5 CLK = ~CLK;

    // Golden model
    reg signed [W2-1:0] exp_M;
    reg signed [W3-1:0] exp_P;

    localparam PIPELINE_LATENCY = 3;

    // queue to track expected outputs
    reg signed [W2-1:0] exp_M_queue [0:PIPELINE_LATENCY];
    reg signed [W3-1:0] exp_P_queue [0:PIPELINE_LATENCY];

    integer i;

    task push_expected(input signed [W2-1:0] m, input signed [W3-1:0] p);
    begin
        // shift queue
        for (i = PIPELINE_LATENCY; i > 0; i = i - 1) begin
            exp_M_queue[i] = exp_M_queue[i-1];
            exp_P_queue[i] = exp_P_queue[i-1];
        end
        exp_M_queue[0] = m;
        exp_P_queue[0] = p;
    end
    endtask

    // === Checker Task ===
    task check_output(input [W2-1:0] got_M, input [W3-1:0] got_P);
        begin
        if (M !== exp_M_queue[PIPELINE_LATENCY-1])
            $display("[FAIL] time=%0t: M=%0d exp=%0d P=%0d exp=%0d", $time, M, exp_M_queue[PIPELINE_LATENCY-1], P, exp_P_queue[PIPELINE_LATENCY-1]);
        else
            $display("[PASS] time=%0t: M=%0d P=%0d", $time, M, P);
        end
    endtask

    task apply_inputs(input signed [W1-1:0] a, b, d,
                      input signed [W3-1:0] c,
                      input [7:0] opmode);
        begin
            A = a; B = b; D = d; C = c; OPMODE = opmode;
        end
    endtask

    // Stimulus
    initial begin
        // Init
        {A,B,D,C} = 0;
        CARRYIN = 0;
        OPMODE=0;
        {CEA,CEB,CEC,CED,CEM,CEOPMODE,CEP,CECARRYIN} = {8{1'b1}};
        {RSTA,RSTB,RSTC,RSTD,RSTM,RSTOPMODE,RSTP,RSTCARRYIN} = {8{1'b0}};
        PCIN = 0; BCIN = 0;

        // Reset
        RST = 1;
        #12 RST = 0;

        // Case 1: simple multiply
        @(posedge CLK);
        apply_inputs(18'sd3, 18'sd4, 18'sd0, 48'sd0, 8'b00010000); // set OPMODE for multiplier
        exp_M = $signed(A) * $signed(B);
        exp_P = 0; // if post-adder not used
        push_expected(exp_M, exp_P);
        @(posedge CLK);
        check_output(M, P);
        
        // Case 2: pre-adder
        @(posedge CLK);
        apply_inputs(18'sd5, 18'sd2, 18'sd1, 48'sd0, 8'b01010000);
        exp_M = $signed(A) * $signed(D + B);
        exp_P = 0; 
        push_expected(exp_M, exp_P);
        @(posedge CLK);
        check_output(M, P);

        // Randomized tests
        repeat (10) begin
            @(posedge CLK);
            apply_inputs($random, $random, $random, $random, $random);
            @(posedge CLK);
            check_output(M, P);
        end

        $display("Simulation finished");
        $finish;
    end

endmodule
