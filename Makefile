root_dir := $(PWD)
bld_dir := ./build
uvm_dir := ./uvm-core-2020.3.1/src
src_dir := ./src

PATTERN := 

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
	+define+$(PATTERN) \
	+define$(DEBUG_DEF)$(FSDB_DEF) \
	+define+UVM_CMDLINE_NO_DPI \
	+define+UVM_REGEX_NO_DPI 

clean :
	rm -rf $(bld_dir)
