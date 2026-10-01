module rom #(
    parameter ADDR_WIDTH = 14
)(
    input  wire        clk,
    input  wire [31:0] addr,
    output wire [31:0] rdata
);

    reg [31:0] mem [0:4095];

    initial begin
        $readmemh("Snake/firmware_words.hex", mem);
    end

    assign rdata = mem[addr[13:2]];

endmodule
