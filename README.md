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
* GNU Make
* Lattice ECP5 Yosys toolchain (I used the toolchain as specified here:
https://orangecrab-fpga.github.io/orangecrab-hardware/r0.2/docs/getting-started/)
* `litedram` Python package