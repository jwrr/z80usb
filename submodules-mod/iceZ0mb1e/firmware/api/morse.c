
#include "icez0mb1e.h"
#include "led.h"
#include "simpletimer.h"
#include "usb.h"

static uint16_t dit_time_ms;

void morse_set_wpm(uint8_t wpm)
{
    dit_time_ms = 1200 / wpm; // 6*1000/(5*wpm)
}


static void dit() { led_blink(dit_time_ms, dit_time_ms); }
static void dah() { led_blink(3*dit_time_ms, dit_time_ms); }
static void endsym() { led_blink(0, 2*dit_time_ms); } // this is actually 3*dit
static void endword() { led_blink(0, 6*dit_time_ms); } // this is actually 7*dit

static void didah(const char* str)
{
    char c = ' ';
    for (int i=0; str[i]!='\0'; i++) {
        c = str[i];
        switch (c) {
            case '.': dit(); break;
            case '_': dah(); break;
            case ' ': endword(); break;
        }
    }
    if (c!=' ') endsym();
}


static uint8_t echo_to_usb;
void morse_set_echo_to_usb(uint8_t echo)
{
    echo_to_usb = echo;
}

static uint8_t stop_on_usb;
void morse_set_stop_on_usb(uint8_t stop_on_usb)
{
    stop_on_usb = stop_on_usb;
}




void morse_putc(char c)
{
/*
  di    = 1 unit
  dah   = 3*di
  intra_char_time = 1*di  -- time between dits,  dahs
  inter_char_time = 3*di  -- time between letters
  inter_word_time = 7*di  -- time between words
  word
  . = di+space   = 2
  _ = 2*di+space = 4
  s = 2*space    = 2 (this is really 3 spaces. the previous symbol includes a trailing space)
  w = 6*space    = 6 (this is really 7 spaces. the previous symbol includes a trailing space)
  paris = ".__.s._s._.s..s...w" = 2+4+4+2+2+ 2+4+2+ 2+4+2+2+ 2+2+2+ 2+2+2+6 = 14+8+10+6+12 = 50

  1wpm = 1*paris/minute = 50 di / 60sec; Tdi = 1.2sec per di
  5wpm = (1.2sec/di) / 5 = 0.240sec/di
  13wpm = 1.2 / 13 = 0.092 sec/di
  20wpm = 1.2 / 20 = 0.06 sec/di

*/

    const char* letters[] = {
        "._",     // 0 a
        "_...",   // 1 b
        "_._.",   // 2 c
        "_..",    // 3 d
        ".",      // 4 e
        ".._.",   // 5 f
        "__.",    // 6 g
        "....",   // 7 h
        "..",     // 8 i
        ".___",   // 9 j
        "_._",    // 10 k
        "._..",   // 11 l
        "__",     // 12 m
        "_.",     // 13 n
        "___",    // 14 o
        ".__.",   // 15 p
        "__._",   // 16 q
        "._.",    // 17 r
        "...",    // 18 s
        "_",      // 19 t
        ".._",    // 20 u
        "..._",   // 21 v
        ".__",    // 22 w
        "_.._",   // 23 x
        "_.__",   // 24 y
        "__..",   // 25 z
        "_____",  // 26 0
        ".____",  // 27 1
        "..___",  // 28 2
        "...__",  // 29 3
        "...._",  // 30 4
        ".....",  // 31 5
        "_....",  // 32 6
        "__...",  // 33 7
        "___..",  // 34 8
        "____.",  // 35 9
        " "       // 36 end of word
//         "", // 0 .
//         "", // 0 ,
//         "", // 0 ?
//         "", // 0 '
//         "", // 0 !
//         "", // 0 /
//         "", // 0 (
//         "", // 0 )
//         "", // 0 &
//         "", // 0 :
//         "", // 0 ;
//         "", // 0 =
//         "", // 0 +
//         "", // 0 -
//         "", // 0 _
//         "", // 0 "
//         "", // 0 $
//         "", // 0 @
//         ""  // 0 (
    };

    unsigned int offset = 0;
    if ('A' <= c && c <= 'Z') {
        offset = c - 'A';
    } else if ('a' <= c && c <= 'z') {
        offset = c - 'a';
    } else if ('0' <= c && c <= '9') { // number
        offset = c - '0' + 26;
    } else if (c==' ') {
        offset = 36;
    } else {
        return;
    }
    if (echo_to_usb) usb_dat_out = c;
    didah( letters[offset] );
} // morse_putc


uint16_t morse_puts(char* str) {
    uint16_t ii = 0;
    for (ii=0; str[ii]!='\0'; ii++)  {
        if (!usb_rx_empty()) break;
        morse_putc(str[ii]);
    }
    return ii;  // return num char sent
}


