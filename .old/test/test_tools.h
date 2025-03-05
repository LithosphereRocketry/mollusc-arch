#ifndef TEST_TOOLS_H
#define TEST_TOOLS_H

#include <string>
#include <iostream>

namespace test {
    struct test_failed: public std::runtime_error {
        test_failed(): std::runtime_error("Test failed") {}
    };

    class testcase {
        public:
            testcase(std::string name): name(name) {}
            
            template <class T, class U>
            inline void assertEqual(T value, U target, std::string msg = "") {
                if(value == target) {
                    return;
                }
                std::cerr << name << ": assertion failed: got " << value
                                  << ", expected " << target;
                if(!msg.empty()) { std::cerr << ": " << msg; }
                std::cerr << std::endl;
                fail(msg);
            }

            template <class T, class U>
            inline void assertLess(T value, U target, std::string msg = "") {
                if(value < target) {
                    return;
                }
                std::cerr << name << ": assertion failed: got " << value
                                  << ", expected less than " << target;
                if(!msg.empty()) { std::cerr << ": " << msg; }
                std::cerr << std::endl;
                fail(msg);
            }

            inline void fail(std::string msg = "") {
                std::cerr << name << " failed";
                if(!msg.empty()) { std::cerr << ": " << msg; }
                std::cerr << std::endl;
                throw test_failed();
            }
        private:
            std::string name;
    };
}

#endif