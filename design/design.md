# Design of the MOLLUSC architecture

## Virtual memory

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

Additionally, some bytecode sequences are illegal in all modes. For example, the
bytecode for `jalr` typically contains a two-bit tag specifying the privilege
level and virtual memory status that the jump should "land" in. Executing the 
instruction with the tag representing "physical addressing, user mode" is 
illegal as user-mode always has virtual code addressing; because this is
enforced by the state-transition logic, there is no need for the fetch stage to
verify that virtual addresses are used.