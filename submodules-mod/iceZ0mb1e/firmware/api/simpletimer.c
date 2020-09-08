//
// iceZ0mb1e - FPGA 8-Bit TV80 SoC for Lattice iCE40
// with complete open-source toolchain flow using yosys and SDCC
//
// Copyright (c) 2018 Franz Neumann (netinside2000@gmx.de)
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#include <stdint.h>
#include "icez0mb1e.h"
#include "simpletimer.h"


void timer_start(void)
{
    timer_cfg = 0;
    timer_cfg = 1;
}


void timer_stop(void)
{
    timer_cfg = 0;
}


// 16MHz clock
void timer_delay_ms(uint16_t n)
{
//   timer_del1 = 0x3e; timer_del0 = 0x80;
   timer_del1 = 0x1f; timer_del0 = 0x40;
   timer_del3 = timer_del2 = 0;
   for (unsigned int i=0; i<n; i++) {
       timer_cfg = 3; // start
       while (timer_busy);
   }
}


char usb_read_wait(uint16_t timeout_ms)
{
    timer_start();
    uint16_t cnt = 0;
    while ( (usb_status & 0x01) == 0) {
        timer_delay_ms(1);
        if (timeout_ms > 0) {
            cnt++;
            if (cnt==timeout_ms) return '\0';
        }
    }
    return usb_dat_in;
}


