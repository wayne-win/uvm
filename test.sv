class car;
    static int count = 0;

    int id;

    int speed;
    int weight;
    int price;

    function new();
        id = count++;
    endfunction 

    function void set(int s, int w, int p);
        speed = s;
        weight = w;
        price = p;
    endfunction

    function void get();
        $display("Speed: %0d", speed);
        $display("Weight: %0d", weight);
        $display("Price: %0d", price);
    endfunction
endclass

module tb;
    car c;
    car d;

    initial begin
        c = new();
        $display("count value after c newed : %0d", c.count);
        c.set(100, 2000, 500000);
        c.get();

        d = new();
        // d = new c;
        // d = c;
        $display("count value after d newed : %0d", d.count);
        d.set(200, 3000, 600000);
        c.get();

    end

endmodule