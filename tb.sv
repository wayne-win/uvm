import uvm_pkg::*;
`include "uvm_macros.svh"

`include "pe.sv"
//----------------
//  sequence_item
//----------------
class pe_seq_item extends uvm_sequence_item;
    `uvm_object_utils(pe_seq_item)

    rand logic[1:0] op;
    rand bit        op_en;
    rand int op_a;
    rand logic[7:0] op_b;
    rand logic[7:0] op_c;
    bit done;
    int result;

    constraint c1 { soft op_a inside {[5:150]}; }
    constraint c2 { soft op_b < op_a; }

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

    int num = 20;

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

//----------------
//     driver 
//----------------
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
      `uvm_info("m_drv", "Get vif successfull", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      `uvm_info("m_drv", $sformatf("Wait for item from sequencer"), UVM_HIGH)
      seq_item_port.get_next_item(m_item);
      drive_item(m_item);
      seq_item_port.item_done();
    end
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

class pe_monitor extends uvm_monitor;
  `uvm_component_utils(pe_monitor)

  virtual pe_if m_if;
  pe_seq_item item;
  uvm_analysis_port #(pe_seq_item) mon_analysis_port;

  int result;

  function new(string name, uvm_component parent);
      super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pe_if)::get(this, "", "pe_if", m_if))
      `uvm_fatal("m_mon", "Could not get vif")
    else
      `uvm_info("m_mon", "Get vif successfull...", UVM_LOW)
    mon_analysis_port = new("mon_analysis_port", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      @(m_if.cb);
        item = pe_seq_item::type_id::create("item");
        item.op_en = m_if.en;
        item.op = m_if.op;
        item.op_a = m_if.a;
        item.op_b = m_if.b;
        item.op_c = m_if.c;
        item.done = m_if.done;
        item.result = m_if.result;
        mon_analysis_port.write(item);
        
    end
  endtask: run_phase
endclass

class pe_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(pe_scoreboard)

  uvm_analysis_imp  #(pe_seq_item, pe_scoreboard) scb_analysis_imp;

  int score = 0, total = 0;
  int golden;

  function new(string name, uvm_component parent);
      super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb_analysis_imp = new("scb_analysis_port", this);
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB", $sformatf("Simulation finished...., get score: %0d/%0d", score, total), UVM_LOW)
  endfunction

  function int gen_golden(pe_seq_item item);
    case (item.op)
      0: return item.op_a + item.op_b; // Add
      1: return item.op_a - item.op_b; // Sub
      2: return item.op_a * item.op_b; // Mul
      3: return item.op_a * item.op_b + item.op_c; // MAC
      default: begin
        `uvm_error("SCB", $sformatf("Invalid operation: %0d detected", item.op))
        return 'x; // Return 'x for invalid operation
      end
    endcase
  endfunction

  virtual function void write (pe_seq_item item);

    if(item.op_en) begin
      golden = gen_golden(item);
      total ++;
    end 

    if(item.done) begin
      if (item.result == golden) begin
        score++;
      end else begin
        `uvm_error("SCB", $sformatf("Mismatch: Expected %0d, Got %0d", golden, item.result))
      end
    end
  endfunction
endclass
//----------------
// environment env
//----------------
class pe_env extends uvm_env;

  pe_drv m_drv;
  uvm_sequencer #(pe_seq_item) m_sqr;
  pe_seq m_seq;
  pe_monitor m_mon;
  pe_scoreboard m_scb;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_drv = pe_drv::type_id::create("m_drv", this);
    m_sqr = uvm_sequencer#(pe_seq_item)::type_id::create("m_sqr", this);
    m_mon = pe_monitor::type_id::create("m_mon", this);
    m_seq = pe_seq::type_id::create("m_seq");
    m_scb = pe_scoreboard::type_id::create("m_scb", this);
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("ENV", "Connect driver and seqeuncer....", UVM_LOW);
    m_drv.seq_item_port.connect(m_sqr.seq_item_export);
    `uvm_info("ENV", "Connect monitor and scoreboard....", UVM_LOW);
    m_mon.mon_analysis_port.connect(m_scb.scb_analysis_imp);
  endfunction 

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("LABEL", "Started run phase.", UVM_HIGH);
     m_seq.start(m_sqr);
    `uvm_info("LABEL", "Finished run phase.", UVM_HIGH);
    phase.drop_objection(this);
  endtask: run_phase
endclass

//-----------
// module top
//-----------
module top;

  bit clk;
  pe_env environment;

  pe dut(.clk (clk));

  initial begin
    environment = new("m_env");
    // uvm_config_db#(virtual pe_if)::set(null, "m_env.m_drv", "pe_if", dut.pe_if0);
    uvm_config_db#(virtual pe_if)::set(null, "m_env.*", "pe_if", dut.pe_if0);
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