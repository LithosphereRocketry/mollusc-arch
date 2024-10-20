#!/usr/bin/python3

import sys
import itertools
from typing import Callable, Optional

labels: dict[str, int] = {}


def parse_instr(line: int, text: str) -> Optional[tuple[str, str, list[str]]]:
    if ":" in text:
        lbl, untrimmed_instr = text.split(":", 1)
        instr_cond = untrimmed_instr.strip()

        labels[lbl] = line*4
    else:
        instr_cond = text

    if len(instr_cond) == 0:
        return None

    if instr_cond[0] == "?" or instr_cond[0] == "!":
        cond, instr = instr_cond.split(maxsplit=1)
    else:
        instr = instr_cond
        cond = "!x0"
    
    split_instr = instr.split(maxsplit=1)
    if len(split_instr) > 1: 
        args = [arg.strip() for arg in split_instr[1].split(",")]
    else:
        args = []
    
    return (cond, split_instr[0].strip(), args)

regnames: dict[str, int] = {
    "x0": 0, "zero": 0,
    "x1": 1, "s0": 1, "ra": 1,
    "x2": 2, "s1": 2, "sp": 2,
    "x3": 3, "s2": 3,
    "x4": 4, "s3": 4,
    "x5": 5, "a0": 5,
    "x6": 6, "a1": 6,
    "x7": 7, "a2": 7,
    "x8": 8, "a3": 8,
    "x9": 9, "a4": 9,
    "x10": 10, "a5": 10,
    "x11": 11, "a6": 11,
    "x12": 12,
    "x13": 13,
    "x14": 14,
    "x15": 15
}

def resolve(arg: str) -> int:
    if arg in labels:
        return labels[arg]
    else:
        return int(arg)

def cond_arg_mask(cond: str) -> int:
    return regnames[cond[1:]] << 28 | (1 << 23 if cond[0] == "?" else 0)

def reg_arg_mask(args: list[str]) -> int:
    return regnames[args[0]] << 24 | regnames[args[1]] << 12 | regnames[args[2]]

def imm_arg_mask(args: list[str]) -> int:
    return regnames[args[0]] << 24 | regnames[args[1]] << 12 | (resolve(args[2]) & 0x7FF)

def long_arg_mask(reg: str, imm: int) -> int:
    return regnames[reg] << 24 | (imm & 0x1FFFFF)

# store operations have 3 inputs rather than 2 inputs and 1 output
def reg_store_arg_mask(args: list[str]) -> int:
    return regnames[args[0]] << 16 | regnames[args[1]] << 12 | regnames[args[2]]

def imm_store_arg_mask(args: list[str]) -> int:
    return regnames[args[0]] << 16 | regnames[args[1]] << 12 | (resolve(args[2]) & 0x7FF)


instr_table: dict[str, Callable[[int, tuple[str, str, list[str]]], int]] = {
    "add": lambda _, instr: (cond_arg_mask(instr[0]) |
                             0x00000000 |
                             reg_arg_mask(instr[2])),
    "addi": lambda _, instr: (cond_arg_mask(instr[0]) |
                              0x00080000 |
                              imm_arg_mask(instr[2])),
    "subi": lambda _, instr: (cond_arg_mask(instr[0]) |
                              0x00090000 |
                              imm_arg_mask(instr[2])),
    "ldp": lambda _, instr: (cond_arg_mask(instr[0]) |
                             0x00140000 |
                             reg_arg_mask(instr[2])),
    "ldpi": lambda _, instr: (cond_arg_mask(instr[0]) |
                             0x001C0000 |
                             imm_arg_mask(instr[2])),
    "jx": lambda _, instr: (cond_arg_mask(instr[0]) |
                             0x00170000 |
                             reg_arg_mask(instr[2])),
    "jxi": lambda _, instr: (cond_arg_mask(instr[0]) |
                             0x001F0000 |
                             imm_arg_mask(instr[2])),
    "stpi": lambda _, instr: (cond_arg_mask(instr[0]) |
                              0x0C100800 | 
                              imm_store_arg_mask(instr[2])),
    "j": lambda pc, instr: (cond_arg_mask(instr[0]) |
                            0x00200000 | 
                            long_arg_mask(instr[2][0],
                                          (resolve(instr[2][1]) - pc) >> 2)),
    "const": lambda _, instr: resolve(instr[2][0]),
}

with open(sys.argv[1], "r") as asmfile:
    asmlines = [line.split(";", 1)[0].strip() for line in asmfile]
    text_instrs = []
    for l in asmlines:
        instr = parse_instr(len(text_instrs), l)
        if instr is not None:
            text_instrs.append(instr)        
    bytecode = [instr_table[instr[1]](ind*4, instr) for ind, instr in enumerate(text_instrs)]
    if len(bytecode) % 4 != 0:
        bytecode += [0] * (4 - len(bytecode) % 4)
    # my python version doesn't have itertools.batched
    print({n : hex(v) for n, v in labels.items()})
    with open(sys.argv[2], "w") as hexfile:
        for i in range(0, len(bytecode), 4):
            hexfile.write("{0:08x}{1:08x}{2:08x}{3:08x}\n"
                          .format(bytecode[i+3], bytecode[i+2], bytecode[i+1], bytecode[i]))

