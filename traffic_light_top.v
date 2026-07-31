//=============================================================
// Traffic Light Controller with Emergency Priority Override
// Main design file: clock_divider, fsm_controller,
// output_decoder, and top-level module
//=============================================================

//----------------------------------------------------
// Clock Divider
// Converts fast board clock into a slow 1Hz tick pulse
//----------------------------------------------------
module clock_divider #(
    parameter COUNT_MAX = 100_000_000 - 1   // 100MHz -> 1Hz. Override for simulation.
)(
    input  wire clk,
    input  wire rst,
    output reg  tick
);
    reg [26:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            tick    <= 0;
        end else if (counter == COUNT_MAX) begin
            counter <= 0;
            tick    <= 1;
        end else begin
            counter <= counter + 1;
            tick    <= 0;
        end
    end
endmodule


//----------------------------------------------------
// FSM Controller
// Core state machine: normal cycle + priority override
//----------------------------------------------------
module fsm_controller #(
    parameter T_GREEN  = 10,
    parameter T_YELLOW = 3,
    parameter T_ALLRED = 2
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,
    input  wire       priority_ns,
    input  wire       priority_ew,
    output reg [2:0]  state
);
    localparam NS_GREEN    = 3'b000;
    localparam NS_YELLOW   = 3'b001;
    localparam EW_GREEN    = 3'b010;
    localparam EW_YELLOW   = 3'b011;
    localparam ALL_RED     = 3'b100;
    localparam PRIORITY_NS = 3'b101;
    localparam PRIORITY_EW = 3'b110;

    reg [3:0] timer;
    reg       priority_side; // 0 = NS requested, 1 = EW requested

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= NS_GREEN;
            timer         <= T_GREEN;
            priority_side <= 0;
        end
        else if (tick) begin
            if (timer != 0) begin
                timer <= timer - 1;
            end
            else begin
                case (state)

                    NS_GREEN: begin
                        if (priority_ns || priority_ew) begin
                            state         <= ALL_RED;
                            timer         <= T_ALLRED;
                            priority_side <= priority_ew; // EW wins if both
                        end else begin
                            state <= NS_YELLOW;
                            timer <= T_YELLOW;
                        end
                    end

                    NS_YELLOW: begin
                        state <= EW_GREEN;
                        timer <= T_GREEN;
                    end

                    EW_GREEN: begin
                        if (priority_ns || priority_ew) begin
                            state         <= ALL_RED;
                            timer         <= T_ALLRED;
                            priority_side <= priority_ns ? 1'b0 : 1'b1;
                        end else begin
                            state <= EW_YELLOW;
                            timer <= T_YELLOW;
                        end
                    end

                    EW_YELLOW: begin
                        state <= NS_GREEN;
                        timer <= T_GREEN;
                    end

                    ALL_RED: begin
                        state <= priority_side ? PRIORITY_EW : PRIORITY_NS;
                    end

                    PRIORITY_NS: begin
                        if (!priority_ns) begin
                            state <= NS_GREEN;
                            timer <= T_GREEN;
                        end
                    end

                    PRIORITY_EW: begin
                        if (!priority_ew) begin
                            state <= NS_GREEN;
                            timer <= T_GREEN;
                        end
                    end

                    default: state <= NS_GREEN;
                endcase
            end
        end
    end
endmodule


//----------------------------------------------------
// Output Decoder
// Maps current state to physical LED signals
//----------------------------------------------------
module output_decoder (
    input  wire [2:0] state,
    output reg        ns_red, ns_yellow, ns_green,
    output reg        ew_red, ew_yellow, ew_green
);
    localparam NS_GREEN    = 3'b000;
    localparam NS_YELLOW   = 3'b001;
    localparam EW_GREEN    = 3'b010;
    localparam EW_YELLOW   = 3'b011;
    localparam ALL_RED     = 3'b100;
    localparam PRIORITY_NS = 3'b101;
    localparam PRIORITY_EW = 3'b110;

    always @(*) begin
        // default: all red
        {ns_red, ns_yellow, ns_green} = 3'b100;
        {ew_red, ew_yellow, ew_green} = 3'b100;

        case (state)
            NS_GREEN: begin
                {ns_red, ns_yellow, ns_green} = 3'b001;
                {ew_red, ew_yellow, ew_green} = 3'b100;
            end
            NS_YELLOW: begin
                {ns_red, ns_yellow, ns_green} = 3'b010;
                {ew_red, ew_yellow, ew_green} = 3'b100;
            end
            EW_GREEN: begin
                {ns_red, ns_yellow, ns_green} = 3'b100;
                {ew_red, ew_yellow, ew_green} = 3'b001;
            end
            EW_YELLOW: begin
                {ns_red, ns_yellow, ns_green} = 3'b100;
                {ew_red, ew_yellow, ew_green} = 3'b010;
            end
            ALL_RED: begin
                {ns_red, ns_yellow, ns_green} = 3'b100;
                {ew_red, ew_yellow, ew_green} = 3'b100;
            end
            PRIORITY_NS: begin
                {ns_red, ns_yellow, ns_green} = 3'b001;
                {ew_red, ew_yellow, ew_green} = 3'b100;
            end
            PRIORITY_EW: begin
                {ns_red, ns_yellow, ns_green} = 3'b100;
                {ew_red, ew_yellow, ew_green} = 3'b001;
            end
        endcase
    end
endmodule


//----------------------------------------------------
// Top Module
// Wires clock_divider -> fsm_controller -> output_decoder
//----------------------------------------------------
module traffic_light_top #(
    parameter COUNT_MAX = 100_000_000 - 1,  // override to small value for simulation
    parameter T_GREEN   = 10,
    parameter T_YELLOW  = 3,
    parameter T_ALLRED  = 2
)(
    input  wire clk,          // board oscillator (e.g. 100MHz)
    input  wire rst,
    input  wire priority_ns,
    input  wire priority_ew,
    output wire ns_red, ns_yellow, ns_green,
    output wire ew_red, ew_yellow, ew_green
);
    wire tick;
    wire [2:0] state;

    clock_divider #(
        .COUNT_MAX (COUNT_MAX)
    ) u_clock_divider (
        .clk  (clk),
        .rst  (rst),
        .tick (tick)
    );

    fsm_controller #(
        .T_GREEN  (T_GREEN),
        .T_YELLOW (T_YELLOW),
        .T_ALLRED (T_ALLRED)
    ) u_fsm_controller (
        .clk         (clk),
        .rst         (rst),
        .tick        (tick),
        .priority_ns (priority_ns),
        .priority_ew (priority_ew),
        .state       (state)
    );

    output_decoder u_output_decoder (
        .state     (state),
        .ns_red    (ns_red),
        .ns_yellow (ns_yellow),
        .ns_green  (ns_green),
        .ew_red    (ew_red),
        .ew_yellow (ew_yellow),
        .ew_green  (ew_green)
    );

endmodule
