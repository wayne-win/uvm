import uvm_pkg::*;
`include "uvm_macros.svh"

`include "pe.sv"

class pe_seq_item extends uvm_sequence_item;
    `uvm_object_utils(pe_seq_item)

    rand logic[3:0]  op;
    rand bit         op_en;
    rand logic[63:0] op_a;
    rand logic[63:0] op_b;
    rand logic[63:0] op_c;

    function new(string name = "");
        super.new(name);
    endfunction

    virtual function string convert2str();
      return $sformatf("op_en=%0d, op_a=%0d, ob_b=%0d, op_c=%0d", op_en, op_a, op_b, op_c);
    endfunction
endclass

class pe_seq extends uvm_sequence#(pe_seq_item);
    `uvm_object_utils(pe_seq)

    pe_seq_item m_item;

    int num = 10;

    function new(string name = "");
        super.new(name);
    endfunction

    task body();
      for (int i = 0; i < num; i ++) begin
        m_item = pe_seq_item::type_id::create("m_item");
        start_item(m_item);
        m_item.randomize();
        `uvm_info("SEQ", $sformatf("Generate new item: %s", m_item.convert2str()), UVM_HIGH)
        finish_item(m_item);
      end
      `uvm_info("SEQ", $sformatf("Done generation of %0d items", num), UVM_LOW)
    endtask : body
endclass

class pe_drv extends uvm_driver#(pe_seq_item);
  `uvm_component_utils(pe_drv)

  pe_seq_item m_item;
  virtual pe_if m_if;
  int processed_items = 0;

  function new(string name, uvm_component parent);
      super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pe_if)::get(this, "", "pe_if", m_if))
      `uvm_fatal("m_drv", "Could not get vif")
    else
      `uvm_info("m_drv", "~~~~ Got vif ~~~", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // phase.raise_objection(this);
    // `uvm_info("LABEL", "pe_drv Started run phase.", UVM_LOW);
    forever begin
      `uvm_info("m_drv", $sformatf("Wait for item from sequencer"), UVM_HIGH)
      seq_item_port.get_next_item(m_item);
      drive_item(m_item);
      seq_item_port.item_done();
    end

    // begin
      // int a = 8'h2, b = 8'h3, c = 8'h4;
      // int op = 4'h3;
      // @(m_if.cb);
      // m_if.cb.a <= a;
      // m_if.cb.b <= b;
      // m_if.cb.c <= c;
      // m_if.cb.doAdd <= 1'b1;
      // m_if.cb.op <= op;
      // repeat(2) @(m_if.cb);
      // `uvm_info("RESULT", $sformatf("%0d + %0d = %0d",
      //   a, b, m_if.cb.result), UVM_LOW);
    // end
    // `uvm_info("LABEL", "pe_drv Finished run phase.", UVM_LOW);
    // phase.drop_objection(this);
  endtask: run_phase

  virtual task drive_item(pe_seq_item item);
    `uvm_info("m_drv", $sformatf("Wait for clocking...."), UVM_HIGH)
    @(m_if.cb);
      m_if.cb.en <= item.op_en;
      m_if.cb.op <= item.op;
      m_if.cb.a  <= item.op_a;
      m_if.cb.b  <= item.op_b;
      m_if.cb.c  <= item.op_c;
  endtask : drive_item
endclass

class pe_env extends uvm_env;

  pe_drv m_drv;
  uvm_sequencer #(pe_seq_item) m_sqr;
  pe_seq m_seq;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_drv = pe_drv::type_id::create("m_drv", this);
    m_sqr = uvm_sequencer#(pe_seq_item)::type_id::create("m_sqr", this);
    m_seq = pe_seq::type_id::create("m_seq");
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_drv.seq_item_port.connect(m_sqr.seq_item_export);
  endfunction 

  // task run_phase(uvm_phase phase);
  //   `uvm_info("m_env", "Started run phase.", UVM_LOW);
  //   super.run_phase(phase);
  // endtask: run_phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("LABEL", "Started run phase.", UVM_LOW);
     m_seq.start(m_sqr);
    `uvm_info("LABEL", "Finished run phase.", UVM_LOW);
    phase.drop_objection(this);
  endtask: run_phase
endclass

//----------------
// environment env
//----------------
class env extends uvm_env;

  virtual pe_if m_if;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    `uvm_info("LABEL", "Started connect phase.", UVM_HIGH);
    // Get the interface from the resource database.
    assert(uvm_resource_db#(virtual pe_if)::read_by_name(
      get_full_name(), "pe_if", m_if));
    `uvm_info("LABEL", "Finished connect phase.", UVM_HIGH);
  endfunction: connect_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("LABEL", "Started run phase.", UVM_LOW);
    begin
      int a = 8'h2, b = 8'h3, c = 8'h4;
      int op = 4'h3;
      @(m_if.cb);
      m_if.cb.a <= a;
      m_if.cb.b <= b;
      m_if.cb.c <= c;
      m_if.cb.en <= 1'b1;
      m_if.cb.op <= op;
      repeat(2) @(m_if.cb);
      `uvm_info("RESULT", $sformatf("%0d + %0d = %0d",
        a, b, m_if.cb.result), UVM_LOW);
    end
    `uvm_info("LABEL", "Finished run phase.", UVM_LOW);
    phase.drop_objection(this);
  endtask: run_phase
endclass



//-----------
// module top
//-----------
module top;

  bit clk;
  // env environment;
  pe_env environment;
  pe dut(.clk (clk));

  initial begin
    environment = new("m_env");
    // Put the interface into the resource database.
    // uvm_resource_db#(virtual pe_if)::set("env",
    //   "pe_if", dut.pe_if0);
    uvm_config_db#(virtual pe_if)::set(null, "m_env.m_drv", "pe_if", dut.pe_if0);
    clk = 0;
    run_test();
  end
  
  initial begin
    forever begin
      #(50) clk = ~clk;
    end
  end
  
  initial begin   
      $fsdbDumpfile("top.fsdb");
      $fsdbDumpvars("+struct", "+mda", dut);
  end
  
endmodule