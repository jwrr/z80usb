
#ifndef __MORSE_H
#define __MORSE_H


#include "led.h"
#include "simpletimer.h"

void morse_set_wpm(uint8_t wpm);
void morse_set_echo_to_usb(uint8_t echo);
void morse_set_stop_on_usb(uint8_t stop_on_usb);

void morse_putc(char c);
uint16_t morse_puts(char* str);

#endif
