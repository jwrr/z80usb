# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Edge
from cocotb.triggers import FallingEdge
from cocotb.triggers import RisingEdge
from cocotb.triggers import ClockCycles
from utils.dvtest import DVTest

from cocotb.monitors import Monitor
from cocotb.drivers import BitDriver
from cocotb.binary import BinaryValue
from cocotb.regression import TestFactory
from cocotb.scoreboard import Scoreboard

from monitors.spi import SPIPeripheralMonitor


def spi_input_gen():  # not used yet
    """Generator for input data applied by BitDriver.

    Continually yield a tuple with the number of cycles to be on
    followed by the number of cycles to be off.
    """
    
    while True:
        yield random.randint(1, 128), random.randint(1, 128)



# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------


#### @cocotb.test()
async def run_test(dut):

    en_gpio_loopback_test = False
    en_spi_test = False


    clk = Clock(dut.clk, 10, units="ns")  # Create a 10us period clock on port clk
    cocotb.fork(clk.start())  # Start the clock

    dut.rst = 0

    dut.uart_txd = 0
    await FallingEdge(dut.clk)

    ### =============================================================================================================
    ### GPIO LOOPBACK TEST

    if en_gpio_loopback_test:
        dv = DVTest(dut, "GPIO Loopback", msg_lvl="All")
        dv.info("GPIO Loopback Test")
        for i in range(20000):
            await FallingEdge(dut.clk)
            dut.P2_in <= dut.P1_out.value
            try:
                gpio_value = int(dut.P1_out.value.binstr,2)
                loop_done = True if gpio_value == 0xff else False
            except ValueError:
                gpio_value = 0
                loop_done = False
            if (i+1) % 1000 == 0:
                dv.info("clock = " + str(i+1) +": P1_out = " + str(gpio_value) )
            if loop_done: break

        await Edge(dut.P1_out)

        gpio_result = int(dut.P1_out.value.binstr,2)
        dv.eq(gpio_result, 0, "Error count from DUT")
        dut.P1_in = 0
        await ClockCycles(dut.clk,100)
        dv.done()


    ### =============================================================================================================
    ### SPI TEST


    spi_peripheral = SPIPeripheralMonitor(
        dut=dut,
        cfg = {
            'name' : "SPI Monitor",
            'size' : 8, # bits
            'mode' : 0,
            'lsb_first' : False,
        },
        io = {
            'sclk' : dut.spi_sclk,
            'cs_n' : dut.spi_cs,
            'sdi'  : dut.spi_mosi,
            'sdo'  : dut.spi_miso,
        }
    )

#        spi_peripheral_expect.append( random.randint(0, 127) )
#        spi_peripheral_response.append( random.randint(0, 127) )



    if en_spi_test:

        dv.info("SPI Test (random modes and speeds)")

        spi_n = 15
        spi_peripheral_expect = []
        spi_scoreboard_expect = []
        spi_peripheral_response = []
        for i in range(spi_n):
           val = i
           spi_peripheral_expect.append( val )
           spi_scoreboard_expect.append( val )
           spi_peripheral_response.append( val )

        spi_peripheral.start(spi_peripheral_expect, spi_peripheral_response)

        scoreboard = Scoreboard(dut)
        scoreboard.add_interface(spi_peripheral, spi_scoreboard_expect, strict_type=False)
        random.seed(42)
        err_cnt = 0
        toggle = 0
        for iiii in range(spi_n):

            # SEND BYTE-VALUE TO SEND OVER SPI TO Z80 USING BPIO p2[7:0]
            dut.P2_in.value = spi_peripheral_expect[iiii]

            # SEND MODE AND CLKDIV TO Z80 OVER GPIO P1[7:0]
            # Bit [1:0] mode
            # Bit [2]   toggle (ensure p1_in changes)
            # Bit [6:3] clkdiv (div sys clk)
            # Bit [7]   done
            spi_peripheral.mode = random.randrange(4) # i % 4
            clkdiv = random.randrange(0, 16, 2)
            toggle = (toggle + 4) & 0x04
            P1_in = (clkdiv << 3) | toggle | spi_peripheral.mode
            dut.P1_in.value = P1_in

            # WAIT FOR Z80 TO SEND SPI MESSAGE AND COMPARE WITH EXPECETD VALUE
            dv.info("Waiting for SPI Peripheral ({})".format(iiii))
            await spi_peripheral.peripheral_monitor()

        spi_peripheral.stop()
        dut.P1_in.value = 0x80
        if err_cnt == 0:
            dv.info("SPI Test Passed")
        else:
            dv.info("SPI Test Failed - Error Count = " + str(err_cnt) )

        await ClockCycles(dut.clk,100)

        # Print result of scoreboard.
        dv.is_true(scoreboard.result, "SPI Test Scoreboard")


        ### =============================================================================================================

    en_timer_test = True
    if en_timer_test:
        for i in range(30):
            await ClockCycles(dut.clk,1000)
            print("{} clocks".format(i*1000) )


# Register the test.
factory = TestFactory(run_test)
factory.generate_tests()


