#!/usr/bin/python3

# Frankly given the prevalence of config files and scripting in *nix it's kinda
# absurd that I have to write this program. Has noone thought of this before?

import argparse
import configparser

argparser = argparse.ArgumentParser()
argparser.add_argument("file", type=str, help="The INI-style config file to parse")
argparser.add_argument("section", type=str, help="The section of the file to look in")
argparser.add_argument("entry", type=str, help="The entry to retrieve the value of")
args = argparser.parse_args()

with open(args.file, "r") as f:
    cfg = configparser.ConfigParser()
    cfg.read_file(f)
    print(cfg.get(args.section, args.entry), end=None)