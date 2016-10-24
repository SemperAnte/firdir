# relative to matlab callscript
cd ../sim/ 

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
                                                                                                                 
vlib rtl_work
vmap work rtl_work

file copy -force {../rtl/romcoef.mif} {romcoef.mif}
vlog     -work work {../rtl/ramSingle.sv}
vlog     -work work {../rtl/romSingle.sv}
vlog     -work work {../rtl/firdir.sv}
vlog     -work work {tb_firdir.sv}

vsim -t 1ns -L altera_mf_ver -L work -voptargs="+acc" tb_firdir

onbreak {exit -force}
run -all