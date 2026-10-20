#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef uint64_t hwaddr;
#include "philips-demux.inc"
static uint32_t rd(uint64_t addr) { uint64_t v=0; assert(philips_demux_read(addr,4,&v)); return v; }
static void wr(uint64_t addr,uint32_t v) { assert(philips_demux_write(addr,4,v)); }
int main(void)
{
    uint64_t ignored;
    philips_demux_init();
    assert(rd(0x17000)==0 && rd(0x170c0)==0);
    /* Driver halt and queue-drain sequence. */
    wr(0x170c0,rd(0x170c0)|0x81000000);
    assert(rd(0x170c0)&0x40000000);
    wr(0x170c0,rd(0x170c0)&~0x01000000);
    assert(rd(0x170c0)&0x40000000);
    wr(0x17000,(rd(0x17000)&~0xc0000000)|0x40000000);
    assert(((rd(0x17000)>>28)&3)==1);
    /* Driver enable and reset sequences must deassert ack. */
    wr(0x17000,rd(0x17000)&~0xc0000000);
    wr(0x170c0,rd(0x170c0)&~0x80000000);
    assert(!(rd(0x170c0)&0x40000000));
    assert(!(rd(0x17000)&0x30000000));
    wr(0x170c0,rd(0x170c0)|0x81000000);
    wr(0x170c0,(rd(0x170c0)&0xfeff0000)|1);
    wr(0x170c0,(rd(0x170c0)&0xfeff0000)|1);
    wr(0x170c0,rd(0x170c0)&0x7fff0000);
    assert(!(rd(0x170c0)&0xc0000000));
    /* Device-owned status cannot be forged, including byte writes. */
    assert(philips_demux_write(0x170c3,1,0x40));
    assert(!(rd(0x170c0)&0x40000000));
    assert(philips_demux_write(0x170c3,1,0x81));
    assert((rd(0x170c0)&0xc0000000)==0xc0000000);
    wr(0x17000,0x3000abcd);
    assert(rd(0x17000)==0xabcd);
    wr(0x17000,0x4000abcd);
    wr(0x17000,0xc000abcd);
    assert((rd(0x17000)&0x30000000)==0x10000000);
    /* Stock loader uploads then verifies 5600 words. Distinct patterns expose
     * address aliasing and canned-success implementations. */
    for (unsigned i=0;i<5600;i++) {
        wr(0x17010,0xa5b60000u ^ (i*12347u));
        wr(0x1700c,(i<<16)|0x201);
        assert(!(rd(0x1700c)&0xf00));
    }
    for (unsigned i=0;i<5600;i++) {
        wr(0x1700c,(i<<16)|0x101);
        assert(!(rd(0x1700c)&0xf00));
        assert(rd(0x17010)==(0xa5b60000u ^ (i*12347u)));
    }
    wr(0x17010,0xdeadbeef);
    wr(0x1700c,0xffff0201);
    wr(0x1700c,0x00000101);
    assert(rd(0x17010)==0xa5b60000);
    wr(0x1700c,0xffff0101);
    assert(rd(0x17010)==0xdeadbeef);
    wr(0x1700c,0x00000301);
    assert((rd(0x1700c)&0xf00)==0x300);
    wr(0x17000,0);
    wr(0x17000,0x8f000000); /* Exact _DMX_Reset command after upload. */
    assert(((rd(0x17000)>>28)&3)==1);
    wr(0x1700c,0xffff0101);
    assert(rd(0x17010)==0xdeadbeef); /* FTI reset preserves uploaded RAM. */
    /* Never capture unrelated demux MMIO or crossing accesses. */
    assert(!philips_demux_read(0x17004,4,&ignored));
    assert(!philips_demux_write(0x17140,4,1));
    assert(!philips_demux_read(0x17003,2,&ignored));
    assert(!philips_demux_read(0x17000,8,&ignored));
    registered_reset(NULL);
    assert(rd(0x17000)==0 && rd(0x170c0)==0);
    wr(0x1700c,0xffff0101);
    assert(rd(0x17010)==0);
    puts("PASS demux halt/start/reset, 5600-word upload/readback, boundaries, unsupported commands, lanes");
}
