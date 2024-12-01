# Design of the MOLLUSC architecture

## Instruction design

MOLLUSC's instructions are designed with a "RISC orthogonal" philosophy - that
is, instructions limit themselves to one fundamental action, and each operation
has access to the same set of modifiers on its functionality. Specifically,
almost all instructions follow this pattern:

* There is exactly one destination register.
* There are two source values: one is a register, and one is either a register
  or an 11-bit immediate.
* There is additionally a condition register, which may apply either a positive
  (x != 0) or inverted (x == 0) boolean condition to the instruction.
* Regardless of implemented pipeline design, instruction execution order is
  transparent with respect to the order of the instructions as written; that is,
  all results of any given instruction are available to all instructions that
  follow it.

Of course, no rule can be without exceptions; the most notable two are the long
immediate group and the memory write group. Instructions in the long immediate
group, comprised of `j` (relative jump), `lui` (load upper immediate), and
`auipc` (add upper immediate to program counter), take no source registers and
only one source immediate of 21 bits. Instructions in the memory write group,
conversely, have no destination register, and take an additional source
register. Other exceptions to the rules above will be noted as they arise.

## Instructions overview

This section details several groups of MOLLUSC instructions and their typical
usage.

### Basic arithmetic

The simplest group of instructions is the arithmetic group. This includes `add`,
`sub`, `and`, `or`, `xor`, `sl`, `sr`, and `sra`, representing most of the
less hardware-intensive integer and bitwise operations. All of these
instructions may be register-register or register-immediate, with the standard
limit of a signed 11-bit immediate value.

### Constant loading

### Jumps

### Memory access

### Special operations

## Virtual memory

In order to reduce hardware cost and complexity, MOLLUSC typically does not have
a full hardware MMU; nothing forbids a spec-compliant processor from
implementing one, but the reference implementation does not.

## Privilege levels

Modern architectures typically have a variety of privilege levels for various
stages of the boot process. MOLLUSC, by contrast, has only two: user and kernel
level. At kernel level, all instructions which have a valid bytecode translation
are legal. This leaves the system vulnerable to severe corruption in the case of
erroneous or malicious kernel code; however, this is considered a worthwhile
sacrifice in order to preserve simplicity of design.

When not at kernel privilege level, the following actions are illegal:

* Reading or writing to the kernel registers (pta, ecause, ktemp, mode)
* Loading or storing at a physical address
* Loading from a page without read permissions
* Storing to a page without write permissions
* Executing from a page without execute permissions

> Below is probably incorrect, revise once more is nailed down

Additionally, some bytecode sequences are illegal in all modes. For example, the
bytecode for `jalr` typically contains a two-bit tag specifying the privilege
level and virtual memory status that the jump should "land" in. Executing the 
instruction with the tag representing "physical addressing, user mode" is 
illegal as user-mode always has virtual code addressing; because this is
enforced by the state-transition logic, there is no need for the fetch stage to
verify that virtual addresses are used.