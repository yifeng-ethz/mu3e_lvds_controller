create_clock -name control_clk -period 5.818 [get_ports {control_clk}]
create_clock -name data_clk -period 7.273 [get_ports {data_clk}]

set_clock_groups -asynchronous \
    -group [get_clocks {control_clk}] \
    -group [get_clocks {data_clk}]

set_false_path -from [get_ports {control_reset data_reset stim_seed}]
