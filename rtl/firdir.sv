//--------------------------------------------------------------------------------
// Project:       dsplib
// Author:        Shustov Aleksey (SemperAnte), semte@semte.ru
// History:
//    26.05.2021 - created
//    29.06.2021 - added RAM and ROM
//    13.07.2021 - first stable version
//--------------------------------------------------------------------------------
// finite-impulse response filter, direct implementation
// see bit-accurate matlab model
//--------------------------------------------------------------------------------
module firdir
    #(parameter logic [100*8 - 1 : 0]   // 100 symbols max for file path
                      COEF_INIT_FILE = "romcoef.mif",   // ROM coefficients initialization file
                int FIR_ORDER = 511,    // order of filter, i.e. number of filter's coefficients - 1
                int COEF_WIDTH = 18,    // coefficients width [-1 1)
                int DIN_WIDTH = 18,     // input data width [-1 1)
                int ACC_WIDTH = 21,     // accumulator width
                int DOUT_WIDTH = 18,    // output data width [-1 1)
                int DOUT_SHIFT = 1)     // shift left output data with saturation
     (input  logic clk,
      input  logic reset,  // async reset
      
      // avalon ST sink
      input  logic                            asiValid,
      input  logic signed [DIN_WIDTH - 1 : 0] asiData,
      output logic                            asiRdy,
      
      // avalon ST source
      output logic                             asoValid,
      output logic signed [DOUT_WIDTH - 1 : 0] asoData,
      input  logic                             asoRdy);
      
    localparam RAM_ADR_WIDTH = $clog2(FIR_ORDER + 1);
    localparam ROM_ADR_WIDTH = RAM_ADR_WIDTH;
    
    logic afterReset;
    
    logic asiRdy2;
    logic dinRegSel;
    logic signed [DIN_WIDTH - 1 : 0] dinReg;
    logic doutRegSel;
    logic doutFull;
    
    logic firStart, firEnd, firEn;
    logic firBody;
    
    logic shiftCe;
    logic [2 : 0] shiftStart;
    logic [3 : 0] shiftEnd;
    logic [2 : 0] shiftEn;
    
    logic multEn;
    logic signed [DIN_WIDTH - 1 : 0] smp;
    logic signed [DIN_WIDTH + COEF_WIDTH - 1 : 0] mult;       
    
    logic accEn, accSet;
    logic signed [DIN_WIDTH : 0] accSummand;
    logic signed [ACC_WIDTH - 1 : 0] acc;
    logic signed [DOUT_WIDTH - 1 : 0] sat; // comb, saturate result of acc   
      
    // RAM connections
    logic ramWr;  // comb
    logic [RAM_ADR_WIDTH - 1 : 0] ramAdr; // used as counter
    logic signed [DIN_WIDTH - 1 : 0] ramQ;
    // ROM connections
    logic [ROM_ADR_WIDTH - 1 : 0] romAdr; // used as counter
    logic signed [COEF_WIDTH - 1 : 0] romQ;    
    
    // check parameters
    initial begin
        if (ACC_WIDTH - DOUT_SHIFT < DOUT_WIDTH) begin
            $error("Not correct parameters, must be ACC_WIDTH - DOUT_SHIFT >= DOUT_WIDTH.");
            $stop;
        end
    end
    
    // asiRdy control
    always_ff @(posedge clk, posedge reset)
    if (reset) begin
        asiRdy2     <= 1'b0;        
        afterReset <= 1'b0;
    end else begin    
        if (~afterReset) begin // set asiRdy after reset
            asiRdy2     <= 1'b1;
            afterReset <= 1'b1;            
        end else begin
            if (asiValid & asiRdy2)
                asiRdy2 <= 1'b0;
            else if (firEnd)
                asiRdy2 <= 1'b1;                
        end
    end
    assign asiRdy = asiRdy2 & ~doutFull;
    
    // asoValid control
    always_ff @(posedge clk, posedge reset)
    if (reset) begin
        asoValid <= 1'b0;
        asoData  <= '0;
        doutFull <= 1'b0;
    end else begin
        if (doutRegSel & ~doutFull) begin            
            asoValid <= 1'b1;
            asoData  <= sat;            
            doutFull <= 1'b1;
        end else if (asoValid & asoRdy) begin
            asoValid <= 1'b0;
            doutFull <= 1'b0;
        end
    end
    
    // filter start, end, enable
    assign firStart = asiValid & asiRdy;
    assign firEnd = (romAdr == FIR_ORDER);
    assign firEn = firStart | firBody;
    always_ff @(posedge clk, posedge reset)
    if (reset) begin
        firBody <= 1'b0;
    end else begin
        if (firStart)
            firBody <= 1'b1;
        else if (firEnd)
            firBody <= 1'b0;
    end
    
    // enable control
    assign shiftCe = ~doutRegSel | ~doutFull;
    
    assign accSet = shiftStart[2];
    assign dinRegSel = shiftStart[1];
    assign doutRegSel = shiftEnd[3];
    always_ff @(posedge clk, posedge reset)
    if (reset) begin
        shiftStart <= '0;
        shiftEnd   <= '0;
        shiftEn    <= '0;
    end else if (shiftCe) begin
        shiftStart <= {shiftStart[$left(shiftStart) - 1 : 0], firStart};        
        shiftEnd   <= {shiftEnd[$left(shiftEnd) - 1 : 0], firEnd};
        shiftEn    <= {shiftEn[$left(shiftEn) - 1 : 0], firEn};        
    end   
    
    // RAM and ROM address counters
    always_ff @(posedge clk, posedge reset)
    if (reset) begin
        romAdr <= '0;
        ramAdr <= '0;
    end else begin
        if (firEn) begin
            if (romAdr == FIR_ORDER)
                romAdr <= '0;
            else
                romAdr <= romAdr + 1'd1;
                
            if (romAdr == FIR_ORDER)
                ramAdr <= ramAdr;
            else
                ramAdr <= (ramAdr == FIR_ORDER) ? '0 : ramAdr + 1'd1;
        end
    end 
    
    // multiplier
    always_ff @(posedge clk, posedge reset)
    if (reset)
        dinReg <= '0;
    else
        if (asiValid & asiRdy)
            dinReg <= asiData;
    
    assign smp = (dinRegSel) ? dinReg : ramQ; // sample for multiplier
    assign multEn = shiftEn[1];

    always_ff @(posedge clk)
    if (multEn)
        mult <= smp * romQ;        
    
    // accumulator
    assign accEn = shiftEn[2];
    assign accSummand = mult[$left(mult) -: DIN_WIDTH + 1];    
    
    always_ff @(posedge clk)
    if (accEn) begin        
        if (accSet)
            acc <= accSummand;
        else
            acc <= acc + accSummand;
    end
    
    // shift acc output with saturation
    generate
        if (DOUT_SHIFT > 0) begin
            always_comb
            begin 
                if (~acc[ACC_WIDTH - 1] & |acc[ACC_WIDTH - 2 -: DOUT_SHIFT]) // positive overflow
                    sat = {1'b0, {(DOUT_WIDTH - 1){1'b1}}}; // saturate
                else if (acc[ACC_WIDTH - 1] & ~&acc[ACC_WIDTH - 2 -: DOUT_SHIFT]) // negative overflow
                    sat = {1'b1, {(DOUT_WIDTH - 1){1'b0}}}; // saturate
                else
                    sat = acc[ACC_WIDTH - 1 - DOUT_SHIFT : ACC_WIDTH - DOUT_WIDTH - DOUT_SHIFT];         
            end
        end else begin // DOUT_SHIFT = 0
            assign sat = acc[ACC_WIDTH - 1 : ACC_WIDTH - DOUT_WIDTH];
        end
    endgenerate
    
    assign ramWr = asiValid & asiRdy;
    // RAM with samples of input data
    ramSingle
      #(.MEM_TYPE  ("RAM_SINGLE_M10K" ),
        .INIT_FILE (""),
        .DATA_WIDTH(DIN_WIDTH),
        .ADR_WIDTH (RAM_ADR_WIDTH),
        .WORD_NUM  (FIR_ORDER + 1))
    firdirRamSmp
       (.clk(clk),
        .wr (ramWr),
        .adr(ramAdr),
        .a  (asiData),
        .q  (ramQ));    
        
    // ROM with coefficients of filter
    romSingle
      #(.MEM_TYPE  ("ROM_SINGLE_M10K"),
        .INIT_FILE (COEF_INIT_FILE),
        .DATA_WIDTH(COEF_WIDTH),
        .ADR_WIDTH (ROM_ADR_WIDTH),
        .WORD_NUM  (FIR_ORDER + 1))
    firdirRomCoef
       (.clk(clk),
        .adr(romAdr),
        .q  (romQ));   
     
endmodule