//--------------------------------------------------------------------------------
// Project:       rtllib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    01.07.2021 - created
//--------------------------------------------------------------------------------
// Memory implementation module
// ROM, single port
//--------------------------------------------------------------------------------
module romSingle
   #(parameter string MEM_TYPE  = "ROM_SINGLE_M10K",    // "ROM_SINGLE_M10K" or "ROM_SINGLE_RTL"
               logic [100*8 - 1:0] INIT_FILE = "./romcontext.mif",   // initialization file, string type cause modelsim error
               int DATA_WIDTH = 16, // data width
               int ADR_WIDTH = 8,   // address width
               int WORD_NUM = 256)  // number of words
	(input	logic clk,
     input	logic [ADR_WIDTH-1 : 0] adr,
     output logic [DATA_WIDTH-1 : 0] q);
     
    // info
    `define INFO_MODE     
    `ifdef INFO_MODE
    initial begin
        if (MEM_TYPE == "ROM_SINGLE_M10K")
            $display("MEM_TYPE : ROM_SINGLE_M10K"); 
        else if (MEM_TYPE == "ROM_SINGLE_RTL")
            $display("MEM_TYPE : ROM_SINGLE_RTL");
        
        $display("INIT_FILE: %0s", INIT_FILE);
    end
    `endif
    
    generate
        // simple single-port, output registered
        if (MEM_TYPE == "ROM_SINGLE_M10K") begin
            altsyncram
                #(.address_aclr_a        ("NONE"                 ),
                  .clock_enable_input_a  ("BYPASS"               ),
                  .clock_enable_output_a ("BYPASS"               ),
                  .init_file             (INIT_FILE              ),
                  .intended_device_family("Cyclone V"            ),
                  .lpm_hint              ("ENABLE_RUNTIME_MOD=NO"),
                  .lpm_type              ("altsyncram"           ),
                  .numwords_a            (WORD_NUM               ),
                  .operation_mode        ("ROM"                  ),
                  .outdata_aclr_a        ("NONE"                 ),
                  .outdata_reg_a         ("CLOCK0"               ),
                  .ram_block_type        ("M10K"                 ),
                  .widthad_a             (ADR_WIDTH              ),
                  .width_a               (DATA_WIDTH             ),
                  .width_byteena_a       (1                      ))
            altsyncramInst
                (.address_a     (adr             ),
                 .clock0        (clk             ),
                 .q_a           (q               ),
                 .aclr0         (1'b0            ),
                 .aclr1         (1'b0            ),
                 .address_b     (1'b1            ),
                 .addressstall_a(1'b0            ),
                 .addressstall_b(1'b0            ),
                 .byteena_a     (1'b1            ),
                 .byteena_b     (1'b1            ),
                 .clock1        (1'b1            ),
                 .clocken0      (1'b1            ),
                 .clocken1      (1'b1            ),
                 .clocken2      (1'b1            ),
                 .clocken3      (1'b1            ),
                 .data_a        ({DATA_WIDTH{1'b1}}),
                 .data_b        (1'b1            ),
                 .eccstatus     (                ),
                 .q_b           (                ),
                 .rden_a        (1'b1            ),
                 .rden_b        (1'b1            ),
                 .wren_a        (1'b0            ),
                 .wren_b        (1'b0            ));
            
        // rtl description
        end else if (MEM_TYPE == "ROM_SINGLE_RTL") begin
      
            logic [DATA_WIDTH-1 : 0] rom [WORD_NUM] ;         
            // initialization needed
         
            always_ff @(posedge clk)
                q <= rom[adr];
			
        // wrong MEM_TYPE
        end else begin
            initial begin
                $error("Not correct parameter, MEM_TYPE.");
                $stop;
            end
        end
    endgenerate      

endmodule