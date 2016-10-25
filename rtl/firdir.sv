//--------------------------------------------------------------------------------
// File Name:     firdir.sv
// Project:       firdir
// Author:        Shustov Aleksey ( SemperAnte ), semte@semte.ru
// History:
//    21.10.2016 - created
//    24.10.2016 - verified with matlab and modelsim
//--------------------------------------------------------------------------------
// finite-impulse response filter, direct implementation
// see bit-accurate matlab model
//--------------------------------------------------------------------------------
module firdir
   #( parameter logic [ 8 * 100 : 0 ]
                    COEF_INIT_FILE = "romcoef.mif", // rom coefficients initialization file
                int FIR_ORDER     = 511,            // order of filter ( number of coef - 1 )
                int COEF_WDT      = 18,             // coef width [-1 1)
                int DIN_WDT       = 16,             // input data width [-1 1)
                int ACC_WDT       = 21,             // accumulator width
                int DOUT_WDT      = 16,             // output data width [-1 1)
                int DOUT_SHIFT    = 1 )             // shift left output data with saturate
    ( input  logic                            clk,
      input  logic                            reset,  // async reset
      
      input  logic                            st,     // start calc 
      input  logic signed [ DIN_WDT - 1 : 0 ] din,    // data in
      
      output logic                            rdy,    // ready for new data on din
      output logic                            nres,   // new result is ready on dout ( pipelined for 3 clocks )
      output logic signed[ DOUT_WDT - 1 : 0 ] dout ); // data out

   localparam int RAM_ADR_WDT = $clog2( FIR_ORDER + 1 );
   localparam int ROM_ADR_WDT = RAM_ADR_WDT;
   
   logic signed            [ DIN_WDT - 1 : 0 ] dReg;
   logic signed [ DIN_WDT + COEF_WDT - 1 : 0 ] mult;
   logic signed            [ ACC_WDT - 1 : 0 ] acc;   
   
   // nres control
   logic           nresEn;
   logic [ 1 : 0 ] nresCnt;
   // comb part, sample for mult
   logic signed  [ DIN_WDT - 1 : 0 ] smp;
   logic signed [ DOUT_WDT - 1 : 0 ] sat; // comb, saturate acc
   
   // ram / rom connections
   logic                                ramWr;  // comb
   logic        [ RAM_ADR_WDT - 1 : 0 ] ramAdr; // counter
   logic signed     [ DIN_WDT - 1 : 0 ] ramQ;
   logic        [ ROM_ADR_WDT - 1 : 0 ] romAdr; // counter
   logic signed    [ COEF_WDT - 1 : 0 ] romQ;   
   
   // fsm
   enum int unsigned { ST0, ST1, ST2, ST3, ST4 } state;
   
   // check parameters
   initial begin
      if ( ACC_WDT - DOUT_SHIFT < DOUT_WDT ) begin
         $error( "Not correct parameters, ACC_WDT - DOUT_SHIFT >= DOUT_WDT" );
         $stop;
      end
   end
   
   always_ff @( posedge clk, posedge reset )
   if ( reset ) begin
      rdy     <= 1'b0;
      nres    <= 1'b0;
      dout    <= '0;
   
      dReg    <= '0;
      mult    <= '0;
      acc     <= '0;
      nresEn  <= 1'b0;
      nresCnt <= 2'b0;
      ramAdr  <= '0;
      romAdr  <= '0;
      state   <= ST0;
   end else begin
      // fsm
      case ( state )
         ST0 : begin
            rdy <= 1'b1; // '1' after reset
            if ( st ) begin
               rdy    <= 1'b0;
               romAdr <= romAdr + 1'd1;
               ramAdr <= ( ramAdr == FIR_ORDER ) ? '0 : ramAdr + 1'd1; // FIR_ORDER + 1 - 1
               dReg   <= din;
               state  <= ST1;
            end
         end
         ST1 : begin
            romAdr <= romAdr + 1'd1;
            ramAdr <= ( ramAdr == FIR_ORDER ) ? '0 : ramAdr + 1'd1;
            state  <= ST2;
         end
         ST2 : begin
            romAdr <= romAdr + 1'd1;
            ramAdr <= ( ramAdr == FIR_ORDER ) ? '0 : ramAdr + 1'd1;
            state  <= ST3;
         end
         ST3 : begin
            romAdr <= romAdr + 1'd1;
            ramAdr <= ( ramAdr == FIR_ORDER ) ? '0 : ramAdr + 1'd1;
            state  <= ST4;
         end
         ST4 : begin
            romAdr <= romAdr + 1'd1;
            if ( romAdr == FIR_ORDER ) begin
               romAdr <= '0;
               rdy    <= 1'b1;
               state  <= ST0;
            end else begin
               ramAdr <= ( ramAdr == FIR_ORDER ) ? '0 : ramAdr + 1'd1;
            end
         end
      endcase
      
      // multiplier with accumulator
      mult <= smp * romQ;
      if ( state == ST3 ) begin // set acc = mult
         acc <= $signed( mult[ DIN_WDT + COEF_WDT - 1 : COEF_WDT - 1 ] ); // width DIN_WDT + 1
      end else begin
         acc <= acc + $signed( mult[ DIN_WDT + COEF_WDT - 1 : COEF_WDT - 1 ] );
      end
      
      // nres and dout control
      if ( state == ST4 && romAdr == FIR_ORDER )
         nresEn <= 1'b1;
      nres <= 1'b0;
      if ( nresEn ) begin
         nresCnt <= nresCnt + 1'd1;
         if ( nresCnt == 2'd3 ) begin
            nresEn <= 1'b0;
            nres   <= 1'b1;
            dout   <= sat; 
         end
      end
   end
   
   assign smp = ( state == ST2 ) ? dReg : ramQ; // sample for mult
   
   // shift with saturation
   generate
      if ( DOUT_SHIFT > 0 ) begin
         always_comb begin 
            if ( ~acc[ ACC_WDT - 1 ] & |acc[ ACC_WDT - 2 -: DOUT_SHIFT ] ) // positive overflow
               sat = { 1'b0, { DOUT_WDT - 1 { 1'b1 } } }; // saturate
            else if ( acc[ ACC_WDT - 1 ] & ~&acc[ ACC_WDT - 2 -: DOUT_SHIFT ] ) // negative overflow
               sat = { 1'b1, { DOUT_WDT - 1 { 1'b0 } } }; // saturate
            else
               sat = acc[ ACC_WDT - 1 - DOUT_SHIFT : ACC_WDT - DOUT_WDT - DOUT_SHIFT ];         
         end
      end else begin // DOUT_SHIFT = 0
         assign sat = acc[ ACC_WDT - 1 : ACC_WDT - DOUT_WDT ];
      end
   endgenerate
   
   assign ramWr = ( state == ST0 && st ) ? 1'b1 : 1'b0;
   // RAM with samples din
   ramSingle
      #( .MEM_TYPE  ( "RAM_SINGLE_M10K" ),
         .INIT_FILE ( ""                ),
         .DATA_WDT  ( DIN_WDT           ),
         .ADR_WDT   ( RAM_ADR_WDT       ),
         .WORD_NUM  ( FIR_ORDER + 1     ) )
   firdirRamSmp
       ( .clk ( clk    ),
         .wr  ( ramWr  ),
         .adr ( ramAdr ),
         .a   ( din    ),
         .q   ( ramQ   ) );    
   
   // ROM with coefficients
   romSingle
      #( .MEM_TYPE  ( "ROM_SINGLE_M10K" ),
         .INIT_FILE ( COEF_INIT_FILE    ),
         .DATA_WDT  ( COEF_WDT          ),
         .ADR_WDT   ( ROM_ADR_WDT       ),
         .WORD_NUM  ( FIR_ORDER + 1     ) )
   firdirRomCoef
       ( .clk ( clk    ),
         .adr ( romAdr ),
         .q   ( romQ   ) );   
     
endmodule