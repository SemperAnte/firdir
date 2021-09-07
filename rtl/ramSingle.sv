//--------------------------------------------------------------------------------
// Project:       rtllib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    29.06.2021 - created
//--------------------------------------------------------------------------------
// Memory implementation module
// RAM, single port
//--------------------------------------------------------------------------------
module ramSingle
   #( parameter string MEM_TYPE  = "RAM_SINGLE_M10K",   // "RAM_SINGLE_M10K" or "RAM_SINGLE_RTL"
                logic [8*100 : 0] INIT_FILE = "./romcontext.mif", // path to initialization file, string type cause modelsim error  
                int DATA_WIDTH = 16,    // data width
                int ADR_WIDTH = 8,      // address width
                int WORD_NUM = 256)     // number of words
   (input  logic clk,
    input  logic wr,
    input  logic [ADR_WIDTH-1 : 0] adr,
    input  logic [DATA_WIDTH-1 : 0] a,
    output logic [DATA_WIDTH-1 : 0] q);
    
    // info
    //`define RAM_INFO_MODE     
    `ifdef RAM_INFO_MODE
    initial begin
        if (MEM_TYPE == "RAM_SINGLE_M10K")
            $display("MEM_TYPE : RAM_SINGLE_M10K"); 
        else if (MEM_TYPE == "RAM_SINGLE_RTL")
            $display("MEM_TYPE : RAM_SINGLE_RTL");
    
        $display("INIT_FILE: %0s", INIT_FILE);
    end
    `endif
   
    generate
        // simple single-port, output registered
        if (MEM_TYPE == "RAM_SINGLE_M10K") begin
            altsyncram
                #( .clock_enable_input_a         ("BYPASS"               ),
                   .clock_enable_output_a        ("BYPASS"               ),
                   .init_file                    (INIT_FILE              ),
                   .intended_device_family       ("Cyclone V"            ),
                   .lpm_hint                     ("ENABLE_RUNTIME_MOD=NO"),
                   .lpm_type                     ("altsyncram"           ),
                   .numwords_a                   (WORD_NUM               ),
                   .operation_mode               ("SINGLE_PORT"          ),
                   .outdata_aclr_a               ("NONE"                 ),
                   .outdata_reg_a                ("CLOCK0"               ),
                   .power_up_uninitialized       ("FALSE"                ),
                   .ram_block_type               ("M10K"                 ),
                   .read_during_write_mode_port_a("NEW_DATA_NO_NBE_READ" ),
                   .widthad_a                    (ADR_WIDTH              ),
                   .width_a                      (DATA_WIDTH             ),
                   .width_byteena_a              (1                      )) 
            altsyncramInst
                ( .address_a      (adr ),
                  .clock0         (clk ),
                  .data_a         (a   ),
                  .wren_a         (wr  ),
                  .q_a            (q   ),
                  .aclr0          (1'b0),
                  .aclr1          (1'b0),
                  .address_b      (1'b1),
                  .addressstall_a (1'b0),
                  .addressstall_b (1'b0),
                  .byteena_a      (1'b1),
                  .byteena_b      (1'b1),
                  .clock1         (1'b1),
                  .clocken0       (1'b1),
                  .clocken1       (1'b1),
                  .clocken2       (1'b1),
                  .clocken3       (1'b1),
                  .data_b         (1'b1),
                  .eccstatus      (    ),
                  .q_b            (    ),
                  .rden_a         (1'b1),
                  .rden_b         (1'b1),
                  .wren_b         (1'b0));
                  
        // rtl description
        end else if (MEM_TYPE == "RAM_SINGLE_RTL") begin
      
            logic [DATA_WIDTH-1 : 0] ram [WORD_NUM]; 
            // variable to hold the registered read address
            logic [ADR_WIDTH- 1 : 0 ] adrReg;

            always @(posedge clk) begin
                if (wr)
                    ram[adr] <= a;
                adrReg <= adr;
            end
            // Continuous assignment implies read returns NEW data.
            // This is the natural behavior of the TriMatrix memory
            // blocks in Single Port mode.  
            assign q = ram[adrReg];
			
        // wrong MEM_TYPE
        end else begin
            initial begin
                $error("Not correct parameter, MEM_TYPE.");
                $stop;
            end
        end
    endgenerate      

endmodule