## FINITE-IMPULSE RESPONSE FILTER, DIRECT IMPLEMENTATION
Digital filter with Finite Impulse Response (FIR).  
Direct Form Filter, requires number of clock cycles equals to number of filter's coefficients for one output sample calculation.  
Use Avalon@ Streaming Interface for input/output data.

Set path to file with coefficient .mif relative to project Quartus@ directory (i.e. if file is in rtl/romcoef.mif then module's parameter must be set to ../rtl/romcoef.mif).

#### Directory matlab
Matlab@ script for filter's coefficients generation in Intel/Alter@ .mif format, also includes bit-accurate model for automatic HDL code verification.

- New filter can be created with Matlab@ tool Filter Designer (type filterDesigner in Matlab@ command window), this tool saves filter in .fda format
- After filter creation, generate m-function with fdafunc.m name: File -> Generate MATLAB Code -> Filter Design Function
- Set data width for fixed-point arithmetic in firdir.m script
- Run first section of firdir.m with command "Run section" for .mif file generation for ROM initialization and text file .txt with input samples for verification with Modelsim@.

#### Directory quartus
Intel@ Quartus filter project.

#### Directory rtl
HDL filter code firdir.sv.  
Top-level wrapper firdirHw.sv for automatic interface recognition with Intel@ Platform Designer.  
Qsys component for Platform Designer instantination.

#### Directory sim
Testbench for HDL code verification with Mentor@ Graphics ModelSim.
