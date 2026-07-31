//=============================================================
// Testbench for traffic_light_top
// Covers: normal cycling, NS priority, EW priority,
//         simultaneous priority requests, reset behavior
//=============================================================
`timescale 1ns/1ps

module traffic_light_tb;

    reg clk;
    reg rst;
    reg priority_ns;
    reg priority_ew;

    wire ns_red, ns_yellow, ns_green;
    wire ew_red, ew_yellow, ew_green;

    // Small values so the whole test runs in a readable amount of time.
    // COUNT_MAX=3 means clock_divider produces a tick every 4 clk edges.
    traffic_light_top #(
        .COUNT_MAX (3),
        .T_GREEN   (4),
        .T_YELLOW  (2),
        .T_ALLRED  (2)
    ) uut (
        .clk         (clk),
        .rst         (rst),
        .priority_ns (priority_ns),
        .priority_ew (priority_ew),
        .ns_red      (ns_red),
        .ns_yellow   (ns_yellow),
        .ns_green    (ns_green),
        .ew_red      (ew_red),
        .ew_yellow   (ew_yellow),
        .ew_green    (ew_green)
    );

    // 100MHz-equivalent clock (10ns period) -- fine for simulation regardless of real freq
    always #5 clk = ~clk;

    // Helper: wait for N ticks worth of time (COUNT_MAX+1 clk edges per tick)
    task wait_ticks(input integer n);
        integer i;
        begin
            for (i = 0; i < n * 4; i = i + 1) begin
                @(posedge clk);
            end
        end
    endtask

    initial begin
        // ---- Init / Reset ----
        clk = 0;
        rst = 1;
        priority_ns = 0;
        priority_ew = 0;
        wait_ticks(1);
        rst = 0;

        $display("---- Test 1: Normal cycling ----");
        wait_ticks(16); // enough to cycle through NS_GREEN -> NS_YELLOW -> EW_GREEN -> EW_YELLOW -> NS_GREEN

        $display("---- Test 2: Priority request from EW during NS_GREEN ----");
        priority_ew = 1;
        wait_ticks(8);   // covers remaining NS_GREEN + ALL_RED + entering PRIORITY_EW
        priority_ew = 0; // clear request
        wait_ticks(6);   // should resume normal cycle at NS_GREEN

        $display("---- Test 3: Priority request from NS during EW_GREEN ----");
        wait_ticks(8);   // advance into EW_GREEN
        priority_ns = 1;
        wait_ticks(8);
        priority_ns = 0;
        wait_ticks(6);

        $display("---- Test 4: Simultaneous priority requests ----");
        priority_ns = 1;
        priority_ew = 1;
        wait_ticks(6);
        priority_ns = 0;
        priority_ew = 0;
        wait_ticks(6);

        $display("---- Test 5: Reset mid-cycle ----");
        wait_ticks(3);
        rst = 1;
        wait_ticks(1);
        rst = 0;
        wait_ticks(6);

        $display("---- All tests complete ----");
        $finish;
    end

    // Print state changes as a readable log instead of raw waveform only
    initial begin
        $monitor("t=%0t rst=%b p_ns=%b p_ew=%b | NS(r,y,g)=%b%b%b EW(r,y,g)=%b%b%b",
                  $time, rst, priority_ns, priority_ew,
                  ns_red, ns_yellow, ns_green,
                  ew_red, ew_yellow, ew_green);
    end

    // Optional: dump waveform for viewing in GTKWave/ModelSim
    initial begin
        $dumpfile("traffic_light_tb.vcd");
        $dumpvars(0, traffic_light_tb);
    end

endmodule
