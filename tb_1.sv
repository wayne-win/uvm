class pe_seq_item extends uvm_sequence_item;
    `uvm_object_utils(pe_seq_item)

    rand logic[1:0]  op;
    rand bit         op_en;
    rand logic[63:0] op_a;
    rand logic[63:0] op_b;
    rand logic[63:0] op_c;

    function new(string name = "");
        super.new(name);
    endfunction
endclass

class pe_seq extends uvm_sequence#(pe_seq_item);
    `uvm_object_utils(pe_seq)

    pe_seq_item req;

    function new(string name = "");
        super.new(name);
    endfunction

    task body();
        req = pe_seq_item::type_id::create("item");

        for (int i = 0; i < 10; i++) begin
            assert(req.randomize());
            `uvm_do(req)
        end
    endtask
endclass

class pe_sqr extends uvm_sequencer#(pe_seq_item);
    `uvm_component_utils(pe_sqr)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        pe_seq seq;
        seq = pe_seq::type_id::create("seq");
    endtask
endclass

class pe_drv extends uvm_driver#(pe_seq_item);
    `uvm_component_utils(pe_drv)

    pe_seq_item seq;
    virtual pe_if pe_if_0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        // Retrieve the virtual interface
        // if (!uvm_config_db#(virtual pe_if)::get(this, "", "pe_if", pe_if_0)) begin
        //     `uvm_fatal("DRV_ERR", "Virtual interface pe_if_0 not found in config_db");
        // end
        seq = pe_seq_item::type_id::create("seq");
    endfunction

    function void connect_phase(uvm_phase phase);
        `uvm_info("LABEL", "Started connect phase.", UVM_HIGH);
        // Get the interface from the resource database.
        assert(uvm_resource_db#(virtual pe_if)::read_by_name(
        get_full_name(), "pe_if", pe_if_0));
        `uvm_info("LABEL", "Finished connect phase.", UVM_HIGH);
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info("", "Run pe_drv test", UVM_LOW)
        begin
            seq_item_port.get_next_item(seq);
            // @(pe_if_0.cb);
            // pe_if_0.cb.op <= seq.op;
            // pe_if_0.cb.op_en <= seq.op_en;
            // pe_if_0.cb.op_a <= seq.op_a;
            // pe_if_0.cb.op_b <= seq.op_b;
            // pe_if_0.cb.op_c <= seq.op_c;
            seq_item_port.item_done();
        end
    endtask
endclass