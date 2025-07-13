`timescale 1ns/1ps

module pwm_generator(
    input wire clk,            
    input wire rst,            
    input wire [6:0] duty_in,      // Input to set duty cycle (0-99)
    input wire [2:0] channel_sel,  // Select which channel to configure (0-7)
    input wire load_duty,          // Signal to load new duty cycle
    input wire [7:0] enable_pwm,   // Enable individual PWM channels
    output reg [7:0] pwm_out  
);

    // Counter
    reg [6:0] count;  
    reg [6:0] duty_cycles [0:7];  // Array to store duty cycles
    
    // Define maximum count
    localparam [6:0] MAX_COUNT = 7'd99;

    integer i;  // For initialization

    // Counter logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 7'd0;
            // Initialize all duty cycles to 0
            for (i = 0; i < 8; i = i + 1) begin
                duty_cycles[i] <= 7'd0;
            end
        end else begin
            // Load new duty cycle when requested
            if (load_duty) begin
                duty_cycles[channel_sel] <= duty_in;
            end
            // Counter logic
            count <= (count == MAX_COUNT) ? 7'd0 : count + 7'd1;
        end
    end

    // PWM generation logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_out <= 8'h00;  // All outputs low on reset
        end else begin
            for (i = 0; i < 8; i = i + 1) begin
                if (enable_pwm[i]) begin  // Only generate PWM if channel is enabled
                    if (count == 7'd0)
                        pwm_out[i] <= 1'b1;
                    else
                        pwm_out[i] <= (count < duty_cycles[i]);
                end else begin
                    pwm_out[i] <= 1'b0;  // Disabled channels stay low
                end
            end
        end
    end

endmodule

// Testbench
module pwm_generator_tb;
    reg clk;
    reg rst;
    reg [6:0] duty_in;
    reg [2:0] channel_sel;
    reg load_duty;
    reg [7:0] enable_pwm;
    wire [7:0] pwm_out;
    
    // Local parameters for testbench
    localparam CLK_PERIOD = 10;
    
    // Instantiate PWM generator
    pwm_generator uut (
        .clk(clk),
        .rst(rst),
        .duty_in(duty_in),
        .channel_sel(channel_sel),
        .load_duty(load_duty),
        .enable_pwm(enable_pwm),
        .pwm_out(pwm_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("pwm_waves.vcd");
        $dumpvars(0, pwm_generator_tb);
        
        // Initial values
        rst = 1;
        duty_in = 0;
        channel_sel = 0;
        load_duty = 0;
        enable_pwm = 8'h00;
        
        // Release reset
        #(CLK_PERIOD*2);
        rst = 0;
        
        // Configure and enable specific channels
        // Channel 0 - 20% duty cycle
        #(CLK_PERIOD);
        channel_sel = 0;
        duty_in = 20;
        load_duty = 1;
        #(CLK_PERIOD);
        load_duty = 0;
        
        // Channel 2 - 40% duty cycle
        #(CLK_PERIOD);
        channel_sel = 2;
        duty_in = 40;
        load_duty = 1;
        #(CLK_PERIOD);
        load_duty = 0;
        
        // Channel 5 - 60% duty cycle
        #(CLK_PERIOD);
        channel_sel = 5;
        duty_in = 60;
        load_duty = 1;
        #(CLK_PERIOD);
        load_duty = 0;
        
        // Enable only configured channels
        #(CLK_PERIOD);
        enable_pwm = 8'b00100101;  // Enable channels 0, 2, and 5
        
        // Run for multiple PWM cycles
        #(CLK_PERIOD*1000);
        
        $display("Simulation completed");
        $finish;
    end
    
    // Monitor PWM outputs
    always @(posedge clk) begin
        if (uut.count == 0)
            $display("Time=%0t Active PWM channels: %b", $time, enable_pwm);
    end

endmodule
