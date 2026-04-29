project_open lvds_controller_syn -revision lvds_controller_syn

create_timing_netlist
read_sdc
derive_clock_uncertainty
update_timing_netlist

report_timing \
    -setup \
    -from_clock data_clk \
    -to_clock data_clk \
    -npaths 20 \
    -detail full_path \
    -file output_files/lvds_controller_syn.data_setup.paths.rpt

report_timing \
    -setup \
    -from_clock control_clk \
    -to_clock control_clk \
    -npaths 20 \
    -detail full_path \
    -file output_files/lvds_controller_syn.control_setup.paths.rpt

report_timing \
    -hold \
    -from_clock data_clk \
    -to_clock data_clk \
    -npaths 10 \
    -detail summary \
    -file output_files/lvds_controller_syn.data_hold.paths.rpt

report_timing \
    -hold \
    -from_clock control_clk \
    -to_clock control_clk \
    -npaths 10 \
    -detail summary \
    -file output_files/lvds_controller_syn.control_hold.paths.rpt

report_ucp \
    -file output_files/lvds_controller_syn.unconstrained.paths.rpt

project_close
