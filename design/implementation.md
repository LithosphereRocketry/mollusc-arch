# MOLLUSC Reference SOC Manual

## Overview

The MOLLUSC Reference SOC is a softcore system-on-chip that acts as a canonical
system-on-chip design for the MOLLUSC architecture. It is designed to be
synthesized on an Orangecrab 25F with a Lattice ECP5 but is designed to be
reasonably portable to other development boards and architectures.

The SOC offers the following processor features:
* 40MHz, tightly pipelined MOLLUSC CPU capable of near-scalar operation
* 16KB shared L1 cache, 16-byte blocked, non-set-associative
* 2KB fixed boot ROM
* 2KB SRAM scratch memory

The SOC also offers the following I/O features:
* RGB LED output with 8-bit hardware PWM per element
* Unbuffered USB CDC serial port

## Memory map

| Addr       | Size       | Cached | Transfer width | Function       | Notes                 |
| ---------- | ---------- | ------ | -------------- | -------------- | --------------------- |
| 0x00000000 | 0x00000800 | yes    | 32b            | Boot ROM       |                       |
| 0x00008000 | 0x00000800 | yes    | 32b            | Boot scratch   |                       |
| 0x00010000 | 0x00001000 | no     | 32b            | DRAM config*   |                       |
| 0x01000000 | 0x00000004 | no     | 32b            | LED controller |                       |
| 0x01000008 | 0x00000008 | no     | 32b            | USB COM port   |                       |
| 0x01008000 | 0x00008000 | no     | 32b            | Video buffer*  | Only first 20KB valid |
| 0xF8000000 | 0x08000000 | yes    | 128b           | DRAM bus*      |                       |

*Projected location, not currently implemented.

## Peripherals

### LED controller

The reference MOLLUSC implementation includes a simple 8-bit-by-3 PWM controller
designed to support simple RGB LEDs such as the one on the OrangeCrab
development board, which operates at a PWM frequency of approximately 100 Hz and
allows a linear range from zero to full duty cycle to three digital outputs.

Control registers for the LED controller are as follows:

| Address    | 31-24  | 23-16      | 15-8        | 7-0       |
| ---------- | ------ | ---------- | ----------- | --------- |
| 0x01000000 | Unused | Blue value | Green value | Red value |