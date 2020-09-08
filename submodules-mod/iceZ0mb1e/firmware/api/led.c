

#include "icez0mb1e.h"
#include "cpu.h"
#include "simpletimer.h"

void oled_reset()
{
    port_b = 0x00;
    delay(50000);
    port_b = 0x01;
    delay(50000);
    port_b = 0x00;
    delay(50000);
    port_b = 0x01;
    delay(50000);
}


void led_on()
{
    port_a = 0x01;
}


void led_off()
{
    port_a = 0x00;
}


void led_blink(unsigned int hi_time, unsigned int low_time)
{
    timer_start(); // if it's already started then this does nothing
    led_on();
    timer_delay_ms(hi_time);

    led_off();
    timer_delay_ms(low_time);
}




