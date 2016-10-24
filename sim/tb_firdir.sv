//--------------------------------------------------------------------------------
// File Name:     tb_firdir.sv
// Project:       firdir
// Author:        Shustov Aleksey ( SemperAnte ), semte@semte.ru
// History:
//       21.10.2016 - created
//       24.10.2016 - done
//--------------------------------------------------------------------------------
// testnench for firdir
//--------------------------------------------------------------------------------
`timescale 1 ns / 100 ps

module tb_firdir();

   localparam int T = 10;
   
   // parameters from generated file
   `include "parms.vh"
   
   logic                            clk;
   logic                            reset;

   logic                            st;
   logic signed [ DIN_WDT - 1 : 0 ] din;
   
   logic                            rdy;
   logic                            nres;
   logic signed[ DOUT_WDT - 1 : 0 ] dout;
   
   firdir
     #( .FIR_ORDER  ( FIR_ORDER  ),
        .COEF_WDT   ( COEF_WDT   ),
        .DIN_WDT    ( DIN_WDT    ),
        .ACC_WDT    ( ACC_WDT    ),
        .DOUT_WDT   ( DOUT_WDT   ),
        .DOUT_SHIFT ( DOUT_SHIFT ) )
   uut
      ( .clk   ( clk   ),
        .reset ( reset ),
        .st    ( st    ),
        .din   ( din   ),
        .rdy   ( rdy   ),
        .nres  ( nres  ),
        .dout  ( dout  ) );
        
   always begin   
      clk = 1'b1;
      #( T / 2 );
      clk = 1'b0;
      #( T / 2 );
   end
   
   initial begin   
      reset = 1'b1;
      #( 10 * T + T / 2 );
      reset = 1'b0;
   end
   
   logic flagEof = 1'b0;
   
   initial begin
      static int dinFile  = $fopen( "din.txt", "r" );  

      
      if ( dinFile == 0 ) begin
         $display( "Cant open file din.txt" );
         $stop;
      end
      
      st = 1'b0;      
      
      wait ( rdy );
      @ ( negedge clk );
      while ( !$feof( dinFile ) ) begin
         # ( $urandom_range( 5, 0 ) * T ); // different delays for testbench
         st = 1'b1;
         // read din sample from file
         $fscanf( dinFile, "%d\n", din );
         # ( T );
         st = 1'b0;
         wait ( rdy );
         @ ( negedge clk );
      end
         
      $fclose( dinFile );
      flagEof = 1'b1;
   end
   
   always @( posedge nres ) begin
      static int doutFile = $fopen( "dout.txt", "w" );
      static int flagFile;
      
      $fwrite( doutFile, "%d\n", dout );
      
      if ( flagEof ) begin
         $fclose( doutFile );
      
         // flag for automatic testbench
         flagFile = $fopen( "flag.txt", "w" );
         $fclose( flagFile );
         $stop;
      end
   end
   
endmodule