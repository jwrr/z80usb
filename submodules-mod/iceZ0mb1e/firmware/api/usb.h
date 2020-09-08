//
#ifndef __USB_H
#define __USB_H

#include <stdint.h>

uint8_t usb_rx_empty();
char usb_rx_getc (uint16_t timeout_ms);

#endif
