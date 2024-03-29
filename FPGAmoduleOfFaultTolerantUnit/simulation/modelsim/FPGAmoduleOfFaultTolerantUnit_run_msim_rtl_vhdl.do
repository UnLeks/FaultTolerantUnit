transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/sidni/Documents/Quartus/FPGAmoduleOfFaultTolerantUnit/FPGAmoduleOfFaultTolerantUnit.vhd}
vcom -93 -work work {C:/Users/sidni/Documents/Quartus/FPGAmoduleOfFaultTolerantUnit/NoTMR.vhd}
vcom -93 -work work {C:/Users/sidni/Documents/Quartus/FPGAmoduleOfFaultTolerantUnit/TMR.vhd}
vcom -93 -work work {C:/Users/sidni/Documents/Quartus/FPGAmoduleOfFaultTolerantUnit/GTMR.vhd}

vcom -93 -work work {C:/Users/sidni/Documents/Quartus/FPGAmoduleOfFaultTolerantUnit/simulation/modelsim/FPGAmoduleOfFaultTolerantUnit.vht}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cycloneiii -L rtl_work -L work -voptargs="+acc"  FPGAmoduleOfFaultTolerantUnit_vhd_tst

add wave *
view structure
view signals
run -all
