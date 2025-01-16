class A;
  int val;

  function new();
    val = 10;
  endfunction 
  
  task test(A obj);
    if(obj == null) begin
      obj = new();
      $display("obj is null");
    end 
    obj.val = 100;
    // end 
  endtask

  function void display();
    $display("val = %0d", val);
  endfunction
endclass

// initial begin 
module tb;

initial begin
  A a, b, c = new();
  c.test(a);
  a.display();
end 

endmodule