module gpio_buttons (
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  buttons,

    input  wire        bus_valid,
    input  wire        bus_write,
    input  wire [31:0] bus_addr,
    input  wire [31:0] bus_wdata,

    output reg  [31:0] bus_rdata
);

    always @(*) begin
        bus_rdata = 32'b0;

        if (bus_addr[3:2] == 2'b00)
            bus_rdata = {28'b0, buttons};
    end

endmodule

