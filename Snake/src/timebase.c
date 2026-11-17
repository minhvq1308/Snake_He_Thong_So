#include "timebase.h"
#include "hw.h"

static uint32_t last_cyc, sub_cyc;

void resync_clock(void)
{
    last_cyc = RD(HUB_CYCLES);
    sub_cyc = 0;
}

void timebase_init(void)
{
    resync_clock();
}

unsigned timebase_poll(void)
{
    uint32_t c = RD(HUB_CYCLES);
    uint32_t d = c - last_cyc;
    unsigned dt = 0;

    last_cyc = c;
    sub_cyc += d;
    while (sub_cyc >= CLK_PER_MS) { sub_cyc -= CLK_PER_MS; dt++; }
    if (dt > 250u) dt = 250u;
    return dt;
}
