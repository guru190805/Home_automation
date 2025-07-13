`timescale 1ns/1ps

// Shift Register Module
module ShiftReg(
    input wire clk,   
    input wire latch,   
    input wire reset,   
    input wire S_in,   
    output reg [7:0] Q
);
    reg [7:0] shift_reg;

    initial begin
        shift_reg = 8'b0;
        Q = 8'b0;
    end

    always @(posedge clk ) begin
        if (reset) begin
            shift_reg <= 8'b0;
            Q <= 8'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], S_in};
            if(latch)
                Q <= shift_reg;
        end
    end
endmodule

// PWM Generator Module
module PWM_Gen(
    input wire clk,    
    output wire [7:0] pwm
);
    localparam COUNTER_MAX = 99;
    
    localparam DUTY_0 = 7'd10;
    localparam DUTY_1 = 7'd20;
    localparam DUTY_2 = 7'd30;
    localparam DUTY_3 = 7'd40;
    localparam DUTY_4 = 7'd50;
    localparam DUTY_5 = 7'd60;
    localparam DUTY_6 = 7'd70;
    localparam DUTY_7 = 7'd80;

    reg [6:0] counter;
    reg [2:0] i;
    reg S_in;
    reg latch;

    // Initialize registers
    initial begin
        counter = 0;
        i = 0;
        S_in = 0;
        latch = 0;
    end

    // Counter logic
    always @(posedge clk) begin
        if(counter >= COUNTER_MAX)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    // PWM and shift register control logic
    always @(posedge clk) begin
        // Generate PWM signal based on counter and duty cycle
        case(i)
            3'd0: S_in <= (counter < DUTY_0);
            3'd1: S_in <= (counter < DUTY_1);
            3'd2: S_in <= (counter < DUTY_2);
            3'd3: S_in <= (counter < DUTY_3);
            3'd4: S_in <= (counter < DUTY_4);
            3'd5: S_in <= (counter < DUTY_5);
            3'd6: S_in <= (counter < DUTY_6);
            3'd7: S_in <= (counter < DUTY_7);
        endcase
        
        // Update channel counter and latch signal
        if(i == 3'b111)
            i <= 0;
        else
            i <= i + 1;
            
        latch <= (i == 3'b111);
    end

    ShiftReg Shft (
        .clk(clk),    
        .latch(latch),    
        .reset(1'b0),  
        .S_in(S_in),    
        .Q(pwm)
    );
endmodule

// Testbench Module
module PWM_Gen_tb;
    reg clk;
    wire [7:0] pwm;
    
    // Instantiate the PWM Generator
    PWM_Gen uut (
        .clk(clk),  
        .pwm(pwm)
    );
    
    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Stimulus and monitoring
    initial begin
        // Enable waveform dumping
        $dumpfile("pwm_test.vcd");
        $dumpvars(0, PWM_Gen_tb);
        
        // Run for multiple PWM cycles
        #10000;  // Run for longer to see multiple PWM cycles
        
        $finish;
    end
    
    // Monitor signals every 100ns
    always @(posedge clk) begin
        if($time % 100 == 0)
            $display("Time=%0t pwm=%b counter=%0d i=%0d S_in=%b latch=%b", 
                     $time, pwm, uut.counter, uut.i, uut.S_in, uut.latch);
    end
endmodule
