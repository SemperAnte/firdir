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

add wave *
add wave -position end -radix unsigned sim:/tb_firdir/uut/romAdr
add wave -position end -radix signed sim:/tb_firdir/uut/romQ
add wave -position end -radix unsigned sim:/tb_firdir/uut/ramAdr
add wave -position end -radix signed sim:/tb_firdir/uut/ramQ

view structure
view signals
run 12 us
wave zoomfull