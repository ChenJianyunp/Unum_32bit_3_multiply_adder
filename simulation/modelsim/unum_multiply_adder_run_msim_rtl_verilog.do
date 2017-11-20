transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+F:/Unum/unumIII_32_3_multiply_adder2 {F:/Unum/unumIII_32_3_multiply_adder2/unum_multiply_adder.v}
vlog -vlog01compat -work work +incdir+F:/Unum/unumIII_32_3_multiply_adder2 {F:/Unum/unumIII_32_3_multiply_adder2/frac_mult.v}

vlog -vlog01compat -work work +incdir+F:/Unum/unumIII_32_3_multiply_adder2/simulation/modelsim {F:/Unum/unumIII_32_3_multiply_adder2/simulation/modelsim/unum_multiply_adder.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  unum_multiply_adder_vlg_tst

add wave *
view structure
view signals
run 0 ps
