# TCL File Generated by Component Editor 18.1
# Wed Jul 21 13:08:00 MSK 2021
# DO NOT MODIFY


# 
# firdir "FIR Direct Form" v1.0
# Shustov Aleksey (SemperAnte), semte@semte.ru 2021.07.21.13:08:00
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module firdir
# 
set_module_property DESCRIPTION ""
set_module_property NAME firdir
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR "Shustov Aleksey (SemperAnte), semte@semte.ru"
set_module_property DISPLAY_NAME "FIR Direct Form"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false
set_module_property ELABORATION_CALLBACK Elaborate

# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL firdirHw
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file firdir.sv SYSTEM_VERILOG PATH firdir.sv
add_fileset_file firdirHw.sv SYSTEM_VERILOG PATH firdirHw.sv TOP_LEVEL_FILE
add_fileset_file ramSingle.sv SYSTEM_VERILOG PATH ramSingle.sv
add_fileset_file romSingle.sv SYSTEM_VERILOG PATH romSingle.sv


# 
# parameters
# 
add_parameter COEF_INIT_FILE STRING ../rtl/romcoef.mif
set_parameter_property COEF_INIT_FILE DEFAULT_VALUE ../rtl/romcoef.mif
set_parameter_property COEF_INIT_FILE DISPLAY_NAME COEF_INIT_FILE
set_parameter_property COEF_INIT_FILE TYPE STRING
set_parameter_property COEF_INIT_FILE UNITS None
set_parameter_property COEF_INIT_FILE HDL_PARAMETER true
add_parameter FIR_ORDER INTEGER 511 ""
set_parameter_property FIR_ORDER DEFAULT_VALUE 511
set_parameter_property FIR_ORDER DISPLAY_NAME FIR_ORDER
set_parameter_property FIR_ORDER WIDTH ""
set_parameter_property FIR_ORDER TYPE INTEGER
set_parameter_property FIR_ORDER UNITS None
set_parameter_property FIR_ORDER ALLOWED_RANGES 1:8192
set_parameter_property FIR_ORDER DESCRIPTION ""
set_parameter_property FIR_ORDER HDL_PARAMETER true
add_parameter COEF_WIDTH INTEGER 18 ""
set_parameter_property COEF_WIDTH DEFAULT_VALUE 18
set_parameter_property COEF_WIDTH DISPLAY_NAME COEF_WIDTH
set_parameter_property COEF_WIDTH WIDTH ""
set_parameter_property COEF_WIDTH TYPE INTEGER
set_parameter_property COEF_WIDTH UNITS None
set_parameter_property COEF_WIDTH ALLOWED_RANGES 1:64
set_parameter_property COEF_WIDTH DESCRIPTION ""
set_parameter_property COEF_WIDTH HDL_PARAMETER true
add_parameter DIN_WIDTH INTEGER 18 ""
set_parameter_property DIN_WIDTH DEFAULT_VALUE 18
set_parameter_property DIN_WIDTH DISPLAY_NAME DIN_WIDTH
set_parameter_property DIN_WIDTH WIDTH ""
set_parameter_property DIN_WIDTH TYPE INTEGER
set_parameter_property DIN_WIDTH UNITS None
set_parameter_property DIN_WIDTH ALLOWED_RANGES 1:64
set_parameter_property DIN_WIDTH DESCRIPTION ""
set_parameter_property DIN_WIDTH HDL_PARAMETER true
add_parameter ACC_WIDTH INTEGER 21 ""
set_parameter_property ACC_WIDTH DEFAULT_VALUE 21
set_parameter_property ACC_WIDTH DISPLAY_NAME ACC_WIDTH
set_parameter_property ACC_WIDTH WIDTH ""
set_parameter_property ACC_WIDTH TYPE INTEGER
set_parameter_property ACC_WIDTH UNITS None
set_parameter_property ACC_WIDTH ALLOWED_RANGES 1:64
set_parameter_property ACC_WIDTH DESCRIPTION ""
set_parameter_property ACC_WIDTH HDL_PARAMETER true
add_parameter DOUT_WIDTH INTEGER 18 ""
set_parameter_property DOUT_WIDTH DEFAULT_VALUE 18
set_parameter_property DOUT_WIDTH DISPLAY_NAME DOUT_WIDTH
set_parameter_property DOUT_WIDTH WIDTH ""
set_parameter_property DOUT_WIDTH TYPE INTEGER
set_parameter_property DOUT_WIDTH UNITS None
set_parameter_property DOUT_WIDTH ALLOWED_RANGES 1:64
set_parameter_property DOUT_WIDTH DESCRIPTION ""
set_parameter_property DOUT_WIDTH HDL_PARAMETER true
add_parameter DOUT_SHIFT INTEGER 1 ""
set_parameter_property DOUT_SHIFT DEFAULT_VALUE 1
set_parameter_property DOUT_SHIFT DISPLAY_NAME DOUT_SHIFT
set_parameter_property DOUT_SHIFT WIDTH ""
set_parameter_property DOUT_SHIFT TYPE INTEGER
set_parameter_property DOUT_SHIFT UNITS None
set_parameter_property DOUT_SHIFT ALLOWED_RANGES 0:64
set_parameter_property DOUT_SHIFT DESCRIPTION ""
set_parameter_property DOUT_SHIFT HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock csi_clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset rsi_reset reset Input 1


# 
# connection point din
# 
add_interface din avalon_streaming end
set_interface_property din associatedClock clock
set_interface_property din associatedReset reset
set_interface_property din errorDescriptor ""
set_interface_property din firstSymbolInHighOrderBits true
set_interface_property din maxChannel 0
set_interface_property din readyLatency 0
set_interface_property din ENABLED true
set_interface_property din EXPORT_OF ""
set_interface_property din PORT_NAME_MAP ""
set_interface_property din CMSIS_SVD_VARIABLES ""
set_interface_property din SVD_ADDRESS_GROUP ""

add_interface_port din asi_din_valid valid Input 1
add_interface_port din asi_din_data data Input DIN_WIDTH
add_interface_port din asi_din_ready ready Output 1


# 
# connection point dout
# 
add_interface dout avalon_streaming start
set_interface_property dout associatedClock clock
set_interface_property dout associatedReset reset
set_interface_property dout errorDescriptor ""
set_interface_property dout firstSymbolInHighOrderBits true
set_interface_property dout maxChannel 0
set_interface_property dout readyLatency 0
set_interface_property dout ENABLED true
set_interface_property dout EXPORT_OF ""
set_interface_property dout PORT_NAME_MAP ""
set_interface_property dout CMSIS_SVD_VARIABLES ""
set_interface_property dout SVD_ADDRESS_GROUP ""

add_interface_port dout aso_dout_valid valid Output 1
add_interface_port dout aso_dout_data data Output DOUT_WIDTH
add_interface_port dout aso_dout_ready ready Input 1

# +----------------------------------------------------------------
# | Elaborate callback
# +----------------------------------------------------------------
proc Elaborate {} {
    set_interface_property din dataBitsPerSymbol  [ get_parameter_value DIN_WIDTH ]
    set_interface_property dout dataBitsPerSymbol [ get_parameter_value DOUT_WIDTH ]
}