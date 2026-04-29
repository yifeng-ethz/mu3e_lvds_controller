QUESTA_HOME ?= /data1/questaone_sim/questasim
QUARTUS_SIM_LIB ?= /data1/intelFPGA/18.1/quartus/eda/sim_lib
ROOT := ../..
WORK := work
LOG := log
ETH_LIC_SERVER := 8161@lic-mentor.ethz.ch

VLIB := $(QUESTA_HOME)/linux_x86_64/vlib
VMAP := $(QUESTA_HOME)/linux_x86_64/vmap
VCOM := $(QUESTA_HOME)/linux_x86_64/vcom
VLOG := $(QUESTA_HOME)/linux_x86_64/vlog
VSIM := $(QUESTA_HOME)/linux_x86_64/vsim

export LM_LICENSE_FILE := $(ETH_LIC_SERVER)
export MGLS_LICENSE_FILE := $(ETH_LIC_SERVER)
export SALT_LICENSE_SERVER := $(ETH_LIC_SERVER)

.PHONY: run compile clean

run: compile
	$(VSIM) -ini $(WORK)/modelsim.ini -c -L altera_mf -work work phy_vendor_smoke_tb \
		-do "run -all; quit -f" | tee $(LOG)/phy_vendor_smoke.log

compile:
	mkdir -p $(WORK) $(LOG)
	cp $(QUESTA_HOME)/modelsim.ini $(WORK)/modelsim.ini
	$(VLIB) $(WORK)/work
	$(VLIB) $(WORK)/altera_mf
	$(VMAP) -ini $(WORK)/modelsim.ini work $(WORK)/work
	$(VMAP) -ini $(WORK)/modelsim.ini altera_mf $(WORK)/altera_mf
	$(VCOM) -ini $(WORK)/modelsim.ini -work altera_mf $(QUARTUS_SIM_LIB)/altera_mf_components.vhd
	$(VCOM) -ini $(WORK)/modelsim.ini -work altera_mf $(QUARTUS_SIM_LIB)/altera_mf.vhd
	$(VCOM) -ini $(WORK)/modelsim.ini -work work $(ROOT)/altera_lvds_rx_28nm.vhd
	$(VLOG) -ini $(WORK)/modelsim.ini -work work -sv phy_vendor_smoke_tb.sv

clean:
	rm -rf $(WORK) $(LOG)
