module timer #(
    parameter integer DIV = 3_375_000
)(
    input  wire        clk,
    input  wire        rst,

    input  wire        bus_valid,
    input  wire        bus_write,
    input  wire [31:0] bus_addr,
    input  wire [31:0] bus_wdata,

    output reg [31:0] bus_rdata
);

    reg [31:0] counter;
    reg        tick;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 32'd0;
            tick    <= 1'b0;
        end
        else begin
            tick <= 1'b0;

            if (counter >= DIV - 1) begin
                counter <= 32'd0;
                tick    <= 1'b1;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end

    always @(*) begin
        bus_rdata = 32'b0;

        if (bus_addr[3:2] == 2'b00)
            bus_rdata = {31'b0, tick};
    end

endmodule
