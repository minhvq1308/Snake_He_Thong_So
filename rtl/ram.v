module ram #(
    parameter ADDR_WIDTH = 14
)(
    input wire        clk,
    input wire        mem_valid,
    input wire        mem_instr,
    input wire        mem_write,
    input wire [3:0]  mem_wstrb,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_wdata,
    output wire [31:0] mem_rdata,
    input wire        we
);

    // =========================================================
    // RAM 16 KB
    // 4096 words x 32 bit
    // =========================================================

    (* ram_style = "block" *)
    reg [31:0] mem [0:4095];

    // =========================================================
    // CPU address:
    // 0x00004000 -> RAM word 0
    // 0x00004004 -> RAM word 1
    // ...
    // =========================================================

    wire [31:0] ram_addr;

    assign ram_addr = mem_addr - 32'h00004000;

    // =========================================================
    // WRITE
    // =========================================================

    always @(posedge clk) begin

        if (mem_valid && mem_write) begin

            if (mem_wstrb[0])
                mem[ram_addr[13:2]][7:0] <= mem_wdata[7:0];

            if (mem_wstrb[1])
                mem[ram_addr[13:2]][15:8] <= mem_wdata[15:8];

            if (mem_wstrb[2])
                mem[ram_addr[13:2]][23:16] <= mem_wdata[23:16];

            if (mem_wstrb[3])
                mem[ram_addr[13:2]][31:24] <= mem_wdata[31:24];

        end

    end

    // =========================================================
    // READ
    // =========================================================

    assign mem_rdata = mem[ram_addr[13:2]];

endmodule
