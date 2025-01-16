root_dir := $(PWD)
bld_dir := ./build
uvm_dir := ./uvm-core-2020.3.1/src
src_dir := ./src

FSDB_DEF :=
ifeq ($(FSDB),1)
FSDB_DEF := +FSDB
else ifeq ($(FSDB),2)
FSDB_DEF := +FSDB_ALL
endif

DEBUG_DEF :=
ifeq ($(DEBUG),1)
DEBUG_DEF := +DEBUG
endif

$(bld_dir):
	mkdir -p $(bld_dir)

run : $(bld_dir)
	cd $(bld_dir); \
	vcs -R -full64 -sverilog +UVM_CONFIG_DB_TRACE $(root_dir)/$(uvm_dir)/uvm.sv $(root_dir)/tb.sv -l vcs.log -debug_access+all +stdout=run.log \
	+incdir+$(root_dir)/$(uvm_dir) \
	+incdir+$(root_dir)/$(src_dir) \
	-timescale=1ns/1ps \
	+define$(DEBUG_DEF)$(FSDB_DEF) \
	+define+UVM_CMDLINE_NO_DPI \
	+define+UVM_REGEX_NO_DPI 
	
run_1 : $(bld_dir)
	cd $(bld_dir); \
	vcs -R -full64 -sverilog $(root_dir)/$(uvm_dir)/uvm.sv $(root_dir)/tb_1.sv -l vcs.log -debug_access+all +stdout=run.log \
	+incdir+$(root_dir)/$(uvm_dir) \
	+incdir+$(root_dir)/$(src_dir) \
	-timescale=1ns/1ps \
	+define$(DEBUG_DEF)$(FSDB_DEF) \
	+define+UVM_CMDLINE_NO_DPI \
	+define+UVM_REGEX_NO_DPI 


run_2 : $(bld_dir)
	cd $(bld_dir); \
	vcs -R -full64 -sverilog $(root_dir)/$(uvm_dir)/uvm.sv $(root_dir)/tb_2.sv -l vcs.log -debug_access+all +stdout=run.log \
	+incdir+$(root_dir)/$(uvm_dir) \
	+incdir+$(root_dir)/$(src_dir) \
	-timescale=1ns/1ps \
	+define$(DEBUG_DEF)$(FSDB_DEF) \
	+define+UVM_CMDLINE_NO_DPI \
	+define+UVM_REGEX_NO_DPI 

clean :
	rm -rf $(bld_dir)
