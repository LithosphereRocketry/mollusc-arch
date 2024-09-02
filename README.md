# MOLLUSC

The Miniature Open Low-Level User-Space Core (MOLLUSC) is a compact 32-bit RISC
CPU architecture with support for usermode restriction and multicore operation,
designed around the capabilities of the OrangeCrab-25F FPGA development board.

As of now this architecture is just an idea and some test components. Further
updates will be forthcoming at some point not particularly soon.

## Goals
* Develop a capable computer architecture with a focus on performance-per-LUT.
* Achieve efficient multicore parallel processing with a minimal amount of
hardware.
* Build a small Unix kernel with enough capability to run simple user programs.
* Hopefully not go insane by the end of the project.

## Dependencies
* Verilator
* GNU Make
* Lattice ECP5 Yosys toolchain (I used the toolchain as specified here:
https://orangecrab-fpga.github.io/orangecrab-hardware/r0.2/docs/getting-started/)
* `litedram` Python package
* `liteeth` Python package (not used, but required for simulation)
* `litescope` Python package (not used, but required for simulation)
* Litex tapcfg (`pip3 install git+https://github.com/litex-hub/pythondata-misc-tapcfg.git`)

## Some notes on Wishbone

The main bus of this processor uses a variation of the Wishbone interface. There
are a couple things about Wishbone which I don't like, and have changed:

* Wishbone really likes to use the terms "master" and "slave" for its devices.
  Somehow it took until very recently for the engineering industry to realize
  that this could lead to potential problems. I will be using the functionally
  equivalent terms "host" and "peripheral" instead. These terms don't have a
  defined meaning in the Wishbone spec, so there is minimal chance of confusion.
* Wishbone has arbitrarily decided that 64 bits is the maximum width of a data
  bus connection. I am relaxing that requirement, and considering any bus width
  as valid.