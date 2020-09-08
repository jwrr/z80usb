//
// iceZ0mb1e - FPGA 8-Bit TV80 SoC for Lattice iCE40
// with complete open-source toolchain flow using yosys and SDCC
//
// Copyright (c) 2020 jwrr.com
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
#include "mini-printf.h"
#include "icez0mb1e.h"
#include "cpu.h"
#include "uart.h"
#include "i2c.h"
#include "spi.h"
#include "led.h"
#include "ssd1306.h"
#include "simpletimer.h"
#include "usb.h"
#include "morse.h"


void main ()
{
    port_cfg = 0x0;            // Make both GPIO ports output
    timer_start();             // Start the simple timer
    morse_set_wpm(5);          // Set words per minute
    morse_set_echo_to_usb(1);  // Echo echo ch to usb_tx as it is blinked
    morse_set_stop_on_usb(1);  // If usb_rx has data then stop sending msg
    char msg[] = "paris ";     // Standard morse code word
    uint16_t timeout_ms = 10000;  // Wait 10 seconds. 0 waits forever.

    while (1) {
    
        // Repeat msg until usb rx data is available
        while (usb_rx_empty()) {
            morse_puts(msg);
        }

        // Send usb rx data until it stops for a long time
        char c;
        while (c = usb_rx_getc(timeout_ms)) {
            morse_putc(c);
        }
    }
//  timer_stop();
}
