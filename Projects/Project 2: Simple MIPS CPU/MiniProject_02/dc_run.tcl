set search_path {"./lib/db"}

set link_library "asap7sc7p5t_AO_LVT_TT_nldm_211120.db \
    asap7sc7p5t_AO_SLVT_TT_nldm_211120.db \
    asap7sc7p5t_INVBUF_LVT_TT_nldm_211120.db \
    asap7sc7p5t_INVBUF_SLVT_TT_nldm_211120.db \
    asap7sc7p5t_OA_LVT_TT_nldm_211120.db \
    asap7sc7p5t_OA_SLVT_TT_nldm_211120.db \
    asap7sc7p5t_SEQ_LVT_TT_nldm_220123.db \
    asap7sc7p5t_SEQ_SLVT_TT_nldm_220123.db \
    asap7sc7p5t_SIMPLE_LVT_TT_nldm_211120.db \
    asap7sc7p5t_SIMPLE_SLVT_TT_nldm_211120.db"

set target_library "asap7sc7p5t_AO_LVT_TT_nldm_211120.db \
    asap7sc7p5t_AO_SLVT_TT_nldm_211120.db \
    asap7sc7p5t_INVBUF_LVT_TT_nldm_211120.db \
    asap7sc7p5t_INVBUF_SLVT_TT_nldm_211120.db \
    asap7sc7p5t_OA_LVT_TT_nldm_211120.db \
    asap7sc7p5t_OA_SLVT_TT_nldm_211120.db \
    asap7sc7p5t_SEQ_LVT_TT_nldm_220123.db \
    asap7sc7p5t_SEQ_SLVT_TT_nldm_220123.db \
    asap7sc7p5t_SIMPLE_LVT_TT_nldm_211120.db \
    asap7sc7p5t_SIMPLE_SLVT_TT_nldm_211120.db"

read_file {"./01_RTL"} -autoread -recursive -format verilog -top core

#project requires clock period < 100ns
create_clock -name "i_clk" -period 9999 -waveform {"0" "45"} {"i_clk"}
set_dont_touch_network [get_clocks i_clk]
set_fix_hold [get_clocks i_clk]

set_dont_touch_network [get_nets i_rst_n]

set_boundary_optimization "*"
set_fix_multiple_port_nets -all -buffer_constant
set_max_area 0

check_design
compile -map_effort medium

report_timing -path full -delay max -max_paths 1 -nworst 1 > ./reports/core.timing
report_power > ./reports/core.power
report_area -nosplit > ./reports/core.area

write -hierarchy -format ddc
write_sdc ./outputs/core.sdc
write_sdf -version 1.0 ./outputs/core.sdf
write -format verilog -hierarchy -output ./outputs/core_syn.v

exit
