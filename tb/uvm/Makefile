# SPDX-License-Identifier: CERN-OHL-S-2.0
# LVDS controller UVM harness

BUILD ?= primary
TEST ?= lvds_base_test
STUB ?= 0
SYMBOL_CAP ?= 1024
RUN_LOG ?= $(LOG_DIR)/$(TEST).log
ALLOW_SIM_ERRORS ?= 0
COVER ?= 0
COVER_METRICS ?= bcesft
UCDB ?= $(COV_DIR)/$(TEST).ucdb
UCDB_TESTNAME ?= $(TEST)
POST_CASE_RESET ?= 0

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

QUESTA_HOME ?= /data1/questaone_sim/questasim
ETH_LIC_SERVER := 8161@lic-mentor.ethz.ch
UVM_HOME ?= $(QUESTA_HOME)/verilog_src/uvm-1.2
QUESTA_ARCH ?= linux_x86_64
VLIB ?= $(QUESTA_HOME)/$(QUESTA_ARCH)/vlib
VLOG ?= $(QUESTA_HOME)/$(QUESTA_ARCH)/vlog
VSIM ?= $(QUESTA_HOME)/$(QUESTA_ARCH)/vsim
VCOVER ?= $(QUESTA_HOME)/$(QUESTA_ARCH)/vcover

export LM_LICENSE_FILE := $(ETH_LIC_SERVER)
export MGLS_LICENSE_FILE := $(LM_LICENSE_FILE)
export SALT_LICENSE_SERVER := $(LM_LICENSE_FILE)
export QSIM_INI := $(QUESTA_HOME)/modelsim.ini

WORK_ROOT := builds/$(BUILD)
WORK_LIB := $(WORK_ROOT)/work
LOG_DIR := log/$(BUILD)
COV_DIR := cov/$(BUILD)

ifeq ($(BUILD),legacy)
  N_LANE := 9
  N_ENGINE := 9
else ifeq ($(BUILD),topo_butterfly_h)
  N_LANE := 12
  N_ENGINE := 4
else ifeq ($(BUILD),topo_butterfly_q)
  N_LANE := 12
  N_ENGINE := 4
else ifeq ($(BUILD),topo_nearest_k)
  N_LANE := 12
  N_ENGINE := 4
else ifeq ($(BUILD),score_w6)
  N_LANE := 4
  N_ENGINE := 2
else ifeq ($(BUILD),score_w16)
  N_LANE := 4
  N_ENGINE := 2
else ifeq ($(BUILD),lane1)
  N_LANE := 1
  N_ENGINE := 1
else ifeq ($(BUILD),lane4)
  N_LANE := 4
  N_ENGINE := 2
else ifeq ($(BUILD),max32)
  N_LANE := 32
  N_ENGINE := 32
else
  N_LANE := 12
  N_ENGINE := 1
endif

POST_CASE_RESET_ARG :=
ifeq ($(POST_CASE_RESET),1)
  POST_CASE_RESET_ARG := +LVDS_POST_CASE_RESET
endif

DEFINES := +define+UVM_NO_DPI +define+LVDS_DV_DEBUG +define+LVDS_N_LANE=$(N_LANE) +define+LVDS_N_ENGINE=$(N_ENGINE)
ifeq ($(STUB),1)
  DEFINES += +define+LVDS_USE_STUB_DUT
  DUT_SRC :=
else
  DUT_SRC := ../../rtl/mu3e_lvds_controller.sv
endif

INCDIRS := +incdir+$(UVM_HOME)/src +incdir+harness +incdir+sequence +incdir+tests +incdir+sva
HARNESS_SRC := \
	harness/lvds_tb_const_pkg.sv \
	harness/lvds_dut_if.sv \
	harness/lvds_dut_stub.sv \
	harness/lvds_uvm_pkg.sv \
	sva/sva_avalon_mm.sv \
	sva/sva_avalon_st.sv \
	sva/sva_routing_excl.sv \
	sva/sva_steering_queue.sv \
	sva/sva_train_fsm.sv \
	sva/sva_score_sat.sv \
	sva/sva_csr_aperture.sv \
	sva/sva_counter_sat.sv \
	sva/sva_engine_attach.sv \
	sva/lvds_coverage.sv \
	tb_top.sv

ifeq ($(COVER),1)
  VLOG_COVER_OPTS := +cover=$(COVER_METRICS)
  VSIM_COVER_OPTS := -coverage
  SIM_DO := coverage save -onexit -testname $(UCDB_TESTNAME) $(UCDB); run -all; quit -f
else
  VLOG_COVER_OPTS :=
  VSIM_COVER_OPTS :=
  SIM_DO := run -all; quit -f
endif

.PHONY: all compile run run_only smoke_stub regression bucket_frame all_buckets_frame coverage_case clean regen_cases

all: run

regen_cases:
	python3 script/generate_case_sequences.py

compile: regen_cases
	mkdir -p $(WORK_ROOT) $(LOG_DIR) $(COV_DIR)
	$(VLIB) $(WORK_LIB)
	$(VLOG) -work $(WORK_LIB) -sv $(VLOG_COVER_OPTS) $(DEFINES) $(INCDIRS) $(UVM_HOME)/src/uvm_pkg.sv $(DUT_SRC) $(HARNESS_SRC) | tee $(LOG_DIR)/compile.log

run: compile
	$(MAKE) run_only

run_only:
	mkdir -p $(LOG_DIR) $(dir $(RUN_LOG)) $(COV_DIR) $(dir $(UCDB))
	$(VSIM) -c -work $(WORK_LIB) $(VSIM_COVER_OPTS) -nodpiexports -suppress 19 -suppress 3009 tb_top \
		+UVM_TESTNAME=$(TEST) +N_LANE=$(N_LANE) +N_ENGINE=$(N_ENGINE) +SYMBOL_CAP=$(SYMBOL_CAP) $(POST_CASE_RESET_ARG) $(EXTRA_ARGS) \
		-do "$(SIM_DO)" | tee $(RUN_LOG)
	! grep -Eq "UVM_(ERROR|FATAL)[[:space:]]+:[[:space:]]*[1-9]" $(RUN_LOG)
	@if [ "$(ALLOW_SIM_ERRORS)" = "0" ]; then \
		! grep -Eq '(^# \\*\\* Error:|^\\*\\* Error:|Errors:[[:space:]]*[1-9])' $(RUN_LOG); \
	fi

coverage_case:
	$(MAKE) COVER=1 POST_CASE_RESET=1 run_only TEST=lvds_base_test RUN_LOG=$(LOG_DIR)/isolated/$(CASE_ID).log UCDB=$(COV_DIR)/isolated/$(CASE_ID).ucdb UCDB_TESTNAME=$(BUILD)_$(CASE_ID) EXTRA_ARGS="+LVDS_CASE_ID=$(CASE_ID)"

smoke_stub:
	$(MAKE) STUB=1 TEST=lvds_b001_read_uid_after_cold_reset_test SYMBOL_CAP=64 run

regression:
	while read case_id; do \
		test -z "$$case_id" && continue; \
		$(MAKE) TEST=lvds_base_test run EXTRA_ARGS="+LVDS_CASE_ID=$$case_id"; \
	done < regression_cases.list

bucket_frame:
	$(MAKE) TEST=lvds_bucket_frame_basic_test run
	$(MAKE) TEST=lvds_bucket_frame_edge_test run
	$(MAKE) TEST=lvds_bucket_frame_prof_test run
	$(MAKE) TEST=lvds_bucket_frame_error_test run

all_buckets_frame:
	$(MAKE) TEST=lvds_all_buckets_frame_test run

clean:
	rm -rf builds
