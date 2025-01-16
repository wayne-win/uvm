program deadlock;

  int m=0;
  integer a=0;
  
  initial begin
    fork
      begin
        while(a!=5)
          if ($time > 3) begin
            $display("thread a, simulation time is %d", $time);
            $finish;
          end
          else begin
            #4;
          end
      end 
      begin
        #5 m <= 1'b1;
        a = 5;
        $display("thread b, simulation time is %d", $time);
        $display("m = %d", m);
      end
    join
  end 
endprogram