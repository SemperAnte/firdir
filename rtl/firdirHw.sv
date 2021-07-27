//--------------------------------------------------------------------------------
// Project:       dsplib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    14.07.2021 - created
//--------------------------------------------------------------------------------
// top-level wrapper for qsys automatic signal recognition
//--------------------------------------------------------------------------------
module firdirHw
    #(parameter logic [100*8 - 1 : 0]   // 100 symbols max for file path
                      COEF_INIT_FILE = "romcoef.mif",   // ROM coefficients initialization file
                int FIR_ORDER = 511,    // order of filter, i.e. number of filter's coefficients - 1
                int COEF_WIDTH = 18,    // coefficients width [-1 1)
                int DIN_WIDTH = 18,     // input data width [-1 1)
                int ACC_WIDTH = 21,     // accumulator width
                int DOUT_WIDTH = 18,    // output data width [-1 1)
                int DOUT_SHIFT = 1)     // shift left output data with saturation
     (input  logic csi_clk,
      input  logic rsi_reset,  // async reset
      
      // avalon ST sink
      input  logic                            asi_din_valid,
      input  logic signed [DIN_WIDTH - 1 : 0] asi_din_data,
      output logic                            asi_din_ready,
      
      // avalon ST source
      output logic                             aso_dout_valid,
      output logic signed [DOUT_WIDTH - 1 : 0] aso_dout_data,
      input  logic                             aso_dout_ready);
      
    firdir
        #(.COEF_INIT_FILE(COEF_INIT_FILE),
          .FIR_ORDER     (FIR_ORDER     ),
          .COEF_WIDTH    (COEF_WIDTH    ),
          .DIN_WIDTH     (DIN_WIDTH     ),
          .ACC_WIDTH     (ACC_WIDTH     ),
          .DOUT_WIDTH    (DOUT_WIDTH    ),
          .DOUT_SHIFT    (DOUT_SHIFT    ))
    firdirInst
         (.clk     (csi_clk       ),
          .reset   (rsi_reset     ),
          .asiValid(asi_din_valid ),
          .asiData (asi_din_data  ),
          .asiRdy  (asi_din_ready ),
          .asoValid(aso_dout_valid),
          .asoData (aso_dout_data ),
          .asoRdy  (aso_dout_ready));   
     
endmodule