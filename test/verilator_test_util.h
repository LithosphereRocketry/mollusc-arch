#ifndef VERILATOR_TEST_UTIL_H
#define VERILATOR_TEST_UTIL_H

#include <string>
#include <iostream>
#include "verilated_vcd_c.h"

namespace vtu {
    template <class DUT>
    class trace {
        private:
            VerilatedVcdC vcd;
            DUT* dut;
            size_t currentTime = 0;
        public:
            trace(std::string filepath, DUT* device): dut(device) {
                Verilated::traceEverOn(true);
                dut->trace(&vcd, 99);
                vcd.open(filepath.c_str());
                vcd.dump(0);
            }

            void advance() {
                vcd.dump(++currentTime);
            }

            ~trace() {
                vcd.close();
            }
    };
}

#endif