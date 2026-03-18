###################################################################

# Created by write_sdc on Sun Mar 15 16:10:30 2026

###################################################################
set sdc_version 2.1

set_units -time ps -resistance kOhm -capacitance fF -voltage V -current mA
set_max_area 0
create_clock [get_ports i_clk]  -period 9999  -waveform {0 45}
