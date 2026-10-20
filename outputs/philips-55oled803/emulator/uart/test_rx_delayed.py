#!/usr/bin/env python3
"""Compile the exact production UART section with deterministic timer adapters."""
import argparse,subprocess,tempfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--expect-old',action='store_true');p.add_argument('--source',type=Path,default=Path('work/philips-emulator/qemu-11.1.2/hw/arm/virt.c'));a=p.parse_args()
source=a.source.read_text()
source=source[source.index('/* MT5891 console:'):source.index('static const MemoryRegionOps philips_uart_ops')]
header=r'''
#include <assert.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#define MIN(a,b) ((a)<(b)?(a):(b))
#define QEMU_CLOCK_VIRTUAL 0
typedef uint64_t hwaddr;
typedef int CharFrontend;
typedef int qemu_irq;
typedef struct QEMUTimer { bool pending; int64_t deadline; } QEMUTimer;
static int64_t now;
static int irq_level;
static QEMUTimer rx_timer,tx_timer;
static int64_t qemu_clock_get_ns(int unused) { return now; }
static bool timer_pending(QEMUTimer *t) { return t->pending; }
static void timer_mod(QEMUTimer *t,int64_t d) { t->deadline=d;t->pending=true; }
static void timer_del(QEMUTimer *t) { t->pending=false; }
static void qemu_set_irq(qemu_irq unused,int level) { irq_level=level; }
static bool qemu_chr_fe_backend_connected(CharFrontend *c) { return false; }
static void qemu_chr_fe_accept_input(CharFrontend *c) {}
static void qemu_chr_fe_write(CharFrontend *c,const uint8_t *b,int n) {}
'''
main=r'''
static void dispatch(int64_t time) {
    now=time;
    assert(rx_timer.pending && rx_timer.deadline<=now);
    rx_timer.pending=false;
    philips_uart_received(NULL);
}
int main(int argc,char **argv) {
    bool old=argc>1;
    philips_uart_rx_timer=&rx_timer;philips_uart_tx_timer=&tx_timer;
    philips_uart_write(NULL,4,0x40,4);
    philips_uart_write(NULL,12,(1U<<17)|(1U<<18),4);
    uint8_t data[256];for(int i=0;i<256;i++)data[i]=i;
    assert(philips_uart_can_receive(NULL)==256);
    philips_uart_receive(NULL,data,256);
    assert(philips_uart_can_receive(NULL)==0);
    assert(philips_uart_rx_count==0);
    assert(rx_timer.deadline==86806);
    // Dispatch the first callback late, after 11 complete wire bytes elapsed.
    dispatch(1000000);
    unsigned observed=philips_uart_rx_count;
    printf("{\"late_first_callback_ns\":1000000,\"received\":%u,\"expected\":11",observed);
    if(old) {
        assert(observed==1);
        printf(",\"result\":\"reproduced elapsed-time loss\"}\n");return 0;
    }
    assert(observed==11 && irq_level);
    assert(rx_timer.deadline==12*86806);
    dispatch(10000000);
    assert(philips_uart_rx_count==31);
    assert(philips_uart_ingress_count==225);
    assert(!rx_timer.pending);
    // Full FIFO applies backpressure: no inline refill and no accumulated burst.
    assert(philips_uart_read(NULL,0,4)==0);
    assert(philips_uart_rx_count==30);
    assert(rx_timer.deadline==now+86806);
    dispatch(now+86806);
    assert(philips_uart_rx_count==31 && !rx_timer.pending);
    for(int i=1;i<=31;i++) assert(philips_uart_read(NULL,0,4)==(unsigned)i);
    assert(philips_uart_rx_count==0);
    dispatch(now+86806);
    assert(philips_uart_rx_count==1);
    // FIFO flush discards staged bytes; queued ingress retains byte order.
    philips_uart_write(NULL,0x50,0x40,4);
    assert(philips_uart_rx_count==0);
    philips_uart_write(NULL,4,0,4);
    dispatch(now+10000000);
    assert(philips_uart_rx_count==1 && !rx_timer.pending);
    assert(philips_uart_read(NULL,0,4)==33);
    assert(philips_uart_rx_count==0 && rx_timer.deadline==now+86806);
    // Drain with one-byte FIFO; source backpressure and 256-byte bound hold.
    for(unsigned i=34;i<256;i++) {
        dispatch(now+86806);assert(philips_uart_rx_count==1);
        assert(philips_uart_read(NULL,0,4)==i);
    }
    assert(!rx_timer.pending && !philips_uart_ingress_count);
    assert(philips_uart_can_receive(NULL)==256 && !irq_level);
    // Idle does not preserve past deadlines for a later host burst.
    now+=1000000000;
    philips_uart_receive(NULL,data,1);
    assert(rx_timer.deadline==now+86806 && !philips_uart_rx_count);
    dispatch(now+86806);assert(philips_uart_read(NULL,0,4)==0);
    printf(",\"result\":\"pass\",\"bounded_fifo_and_ingress\":true,\"backpressure\":true,\"byte_order\":true,\"idle_resets_deadline\":true}\n");
}
'''
with tempfile.TemporaryDirectory(prefix='phuart-harness-') as t:
    path=Path(t);(path/'test.c').write_text(header+source+main)
    subprocess.run(['clang','-std=c11','-Wall','-Wextra','-Wno-unused-parameter','-Wno-unused-function','-Wno-unused-variable','-Wno-sign-compare','-Werror','-fsanitize=address,undefined',str(path/'test.c'),'-o',str(path/'test')],check=True)
    subprocess.run([str(path/'test')]+(['old'] if a.expect_old else []),check=True)
