`timescale 1ns / 1ps

// ============================================================
// Snake SoC
// PicoRV32 + ROM + RAM
//
// Memory map:
//
// 0x00000000 - 0x0000FFFF : ROM 64 KB
// 0x00010000 - 0x00013FFF : RAM 16 KB
//
// CPU reset PC : 0x00000000
// Stack top    : 0x00014000
//
// Firmware:
// Snake/build/snake_rom.hex
// ============================================================

module snake_soc (
    input  wire clk,
    input  wire resetn
);

    // ========================================================
    // PicoRV32 memory interface
    // ========================================================

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;

    reg [31:0] mem_rdata;


    // ========================================================
    // Memory map
    // ========================================================

    localparam ROM_BASE = 32'h00000000;
    localparam ROM_END  = 32'h00010000;

    localparam RAM_BASE = 32'h00010000;
    localparam RAM_END  = 32'h00014000;


    // ========================================================
    // ROM
    //
    // 64 KB / 4 bytes = 16384 words
    // ========================================================

    reg [31:0] rom [0:16383];

integer i;

initial begin
    for (i = 0; i < 16384; i = i + 1)
        rom[i] = 32'h00000013;

    $readmemh("Snake/build/snake_rom.hex", rom, 0, 1053);
end


    // ========================================================
    // RAM
    //
    // 16 KB / 4 bytes = 4096 words
    // ========================================================

    reg [31:0] ram [0:4095];


    // ========================================================
    // ROM select
    // ========================================================

    wire rom_sel;

    assign rom_sel =
        mem_valid &&
        (mem_addr >= ROM_BASE) &&
        (mem_addr < ROM_END);


    // ========================================================
    // RAM select
    // ========================================================

    wire ram_sel;

    assign ram_sel =
        mem_valid &&
        (mem_addr >= RAM_BASE) &&
        (mem_addr < RAM_END);


    // ========================================================
    // Memory ready
    // ========================================================

    assign mem_ready = rom_sel | ram_sel;


    // ========================================================
    // Read data
    // ========================================================

    always @(*) begin

        mem_rdata = 32'h00000000;

        if (rom_sel) begin

            mem_rdata = rom[mem_addr[15:2]];

        end
        else if (ram_sel) begin

            mem_rdata =
                ram[(mem_addr - RAM_BASE) >> 2];

        end

    end


    // ========================================================
    // RAM write
    // ========================================================

    always @(posedge clk) begin

        if (resetn && ram_sel) begin

            if (mem_wstrb[0])
                ram[(mem_addr - RAM_BASE) >> 2][7:0]
                    <= mem_wdata[7:0];

            if (mem_wstrb[1])
                ram[(mem_addr - RAM_BASE) >> 2][15:8]
                    <= mem_wdata[15:8];

            if (mem_wstrb[2])
                ram[(mem_addr - RAM_BASE) >> 2][23:16]
                    <= mem_wdata[23:16];

            if (mem_wstrb[3])
                ram[(mem_addr - RAM_BASE) >> 2][31:24]
                    <= mem_wdata[31:24];

        end

    end


    // ========================================================
    // PicoRV32
    // ========================================================

    picorv32 #(

        .STACKADDR(32'h00014000),

        .PROGADDR_RESET(32'h00000000),

        .ENABLE_IRQ(0),

        .ENABLE_MUL(1),

        .ENABLE_DIV(1),

        .BARREL_SHIFTER(1),

        .COMPRESSED_ISA(1),

        .ENABLE_COUNTERS(1)

    ) cpu (

        .clk(clk),

        .resetn(resetn),

        .mem_valid(mem_valid),

        .mem_instr(mem_instr),

        .mem_ready(mem_ready),

        .mem_addr(mem_addr),

        .mem_wdata(mem_wdata),

        .mem_wstrb(mem_wstrb),

        .mem_rdata(mem_rdata),

        .irq(32'b0)

    );

endmodule
