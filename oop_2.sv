class A;
  protected  int a;
  function int get_a(); get_a = a; endfunction 
  function new(int b); a=b; endfunction
endclass


class B extends A;
    int b = 1000;
    task printa(); $display("a is %d", a); endtask
    function new(); super.new(); endfunction
endclass