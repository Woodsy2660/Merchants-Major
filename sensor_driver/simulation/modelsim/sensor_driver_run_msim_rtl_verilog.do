transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/SharedDir/sensor_driver {/SharedDir/sensor_driver/sonar_pll.v}
vlog -vlog01compat -work work +incdir+/SharedDir/sensor_driver/db {/SharedDir/sensor_driver/db/sonar_pll_altpll.v}
vlog -sv -work work +incdir+/SharedDir/sensor_driver {/SharedDir/sensor_driver/display.sv}
vlog -sv -work work +incdir+/SharedDir/sensor_driver {/SharedDir/sensor_driver/seven_seg.sv}
vlog -sv -work work +incdir+/SharedDir/sensor_driver {/SharedDir/sensor_driver/sonar_range.sv}
vlog -sv -work work +incdir+/SharedDir/sensor_driver {/SharedDir/sensor_driver/top_level.sv}

vlog -sv -work work +incdir+/SharedDir/sensor_driver {/SharedDir/sensor_driver/sensor_driver_tb.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  sensor_driver_tb

add wave *
view structure
view signals
run -all
