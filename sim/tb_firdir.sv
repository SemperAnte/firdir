//--------------------------------------------------------------------------------
// Project:       dsplib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    24.06.2021 - created
//--------------------------------------------------------------------------------
// testbench for firdir
//--------------------------------------------------------------------------------
`timescale 1 ns / 100 ps

module tb_firdir();
    
    localparam time T = 10;
    
    // parameters from generated file
    `include "parms.vh"
    
    logic clk;
    logic reset;
   
    logic                            asiValid;
    logic signed [DIN_WIDTH - 1 : 0] asiData;
    logic                            asiRdy;
    
    logic                             asoValid;
    logic signed [DOUT_WIDTH - 1 : 0] asoData;
    logic                             asoRdy;
   
    firdir
    #(.COEF_INIT_FILE("romcoef.mif"),
      .FIR_ORDER     (FIR_ORDER    ),
      .COEF_WIDTH    (COEF_WIDTH   ),
      .DIN_WIDTH     (DIN_WIDTH    ),
      .ACC_WIDTH     (ACC_WIDTH    ),
      .DOUT_WIDTH    (DOUT_WIDTH   ),
      .DOUT_SHIFT    (DOUT_SHIFT   ))
    uut
      (.clk     (clk     ),
       .reset   (reset   ),
       .asiValid(asiValid),
       .asiData (asiData ),
       .asiRdy  (asiRdy  ),
       .asoValid(asoValid),
       .asoData (asoData ),
       .asoRdy  (asoRdy  ));
    
    // clk
    always begin
        clk = 1'b1;
        #(T/2);
        clk = 1'b0;
        #(T/2);
    end
   
    // reset
    initial begin
        reset = 1'b1;
        #(10*T + T/2);
        reset = 1'b0;
    end
    
    logic flagEof = 1'b0;
    
    always begin
    
        asoRdy = 1'b1;
        # 12us;
        asoRdy = 1'b0;
        # 12us;
    end
    
    initial begin
        static int dinFile = $fopen("din.txt", "r");
        
        if (dinFile == 0) begin
            $display("Can not open file din.txt");
            $stop;
        end
        
        asiValid = 1'b0;
        
        wait (asiRdy);
        @(negedge clk)
        while (!$feof(dinFile)) begin
            asiValid = 1'b1;
            // read din sample from file
            $fscanf(dinFile, "%d\n", asiData);
            #(T);
            asiValid = 1'b0;
            wait(asiRdy);
            @(negedge clk);
        end
        
        $fclose(dinFile);
        flagEof = 1'b1;
    end
    
    always @(posedge asoValid) begin
        static int doutFile = $fopen("dout.txt", "w");
        static int flagFile;
      
        $fwrite(doutFile, "%d\n", asoData);
      
        if (flagEof) begin
            $fclose(doutFile);
      
            // flag for automatic testbench
            flagFile = $fopen("flag.txt", "w");
            $fclose(flagFile);
            $stop;
        end
    end
   
endmodule