#include "Vcore.h"

#ifndef __unix__
#error "Direct simulation requires POSIX libraries"
#endif

#include <deque>
#include <poll.h>
#include <cstdio>
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include "scancodesets.h"
#include "../test/verilator_test_util.h" // TODO: sketchy

const unsigned long clockspeed = 48'000'000UL; // Clock speed
const unsigned long timeincs = 1'000'000'000'000UL; // `timescale 1ps/1ps

bool stdinAvail() {
    struct pollfd pfd = {
        .fd = fileno(stdin),
        .events = POLLIN
    };
    return poll(&pfd, 1, 0) > 0 && pfd.revents & POLLIN;
}

VerilatedContext context;
Vcore core(&context);

const unsigned long clocks_per_frame = clockspeed / 60;
// Assume the keyboard sends scan codes at about 1k/second: https://www.os2museum.com/wp/how-fast-is-a-ps-2-keyboard/
const unsigned long clocks_per_key = clockspeed / 1000;
unsigned long clocks_since_refresh = 0;
unsigned long clocks_since_key = 0;
void step() {
    core.eval();
    context.timeInc(timeincs / clockspeed / 2);
    core.clk = true;
    core.ioclk = true;
    core.eval();
    context.timeInc(timeincs / clockspeed / 2);
    core.clk = false;
    core.ioclk = false;
    core.eval();
    clocks_since_refresh ++;
    clocks_since_key ++;
}

char vga_mem[256*64];
std::deque<uint8_t> key_out;

int main(int, char**) {
    vtu::trace trace("waveforms/sim.vcd", &core);

    // This has slightly different input behavior to an actual TTY because of
    // some quirks in buffering behavior, but it's close enough
    // Reduce the amount of stdin buffering
    setbuf(stdin, NULL);
    // Our magical echo port never stalls
    core.uart_tx_ready = true;

    // SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* window = SDL_CreateWindow("SVGA Display",
                                          SDL_WINDOWPOS_UNDEFINED,
                                          SDL_WINDOWPOS_UNDEFINED,
                                          1280, 1024,
                                          SDL_WINDOW_SHOWN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    SDL_Surface* surf = IMG_Load("assets/charset-bw.png");
    SDL_Texture* char_texture = SDL_CreateTextureFromSurface(renderer, surf);
    SDL_SetTextureBlendMode(char_texture, SDL_BLENDMODE_NONE);
    
    bool quit = false;
    while(!quit) {

        // Check if we should send to TTY
        if(core.uart_rx_ready && core.uart_rx_valid) {
            core.uart_rx_valid = false;
        }
        if(stdinAvail() && !core.uart_rx_valid) {
            core.uart_rx_data = getchar();
            core.uart_rx_valid = true;
        }

        // Check if we should receive from TTY
        if(core.uart_tx_valid) { putchar(core.uart_tx_data); }

        // // Check if we should write to the screen
        // if(core.vga_wr_en) { vga_mem[core.vga_waddr] = core.vga_wdata; }

        // // Check if we should read from the keyboard
        // if(clocks_since_key >= clocks_per_key && !key_out.empty() && core.kb_ready) {
        //     clocks_since_key -= clocks_per_key;
        //     core.kb_data = key_out.front();
        //     key_out.pop_front();
        //     core.kb_valid = true;
        // } else {
        //     core.kb_valid = false;
        // }

        // Check if we should render a new frame
        if(clocks_since_refresh >= clocks_per_frame) {
            clocks_since_refresh -= clocks_per_frame;
            SDL_RenderClear(renderer);
            for(int i = 0; i < 64; i++) {
                for(int j = 0; j < 160; j++) {
                    // Note, only 5/8 of the memory is onscreen
                    char to_draw = vga_mem[i*256 + j];
                    SDL_Rect charregion = { (to_draw % 16) * 8, (to_draw / 16) * 16, 8, 16 };
                    SDL_Rect screenregion = { j*8, i*16, 8, 16 };
                    SDL_RenderCopy(renderer, char_texture, &charregion, &screenregion);
                }
            }
            SDL_Event e;
            while(SDL_PollEvent(&e)) {
                switch(e.type) {
                    case SDL_QUIT:
                        quit = true;
                        break;
                    case SDL_KEYUP:
                        key_out.push_back(0xE0); // PS/2 break code
                        [[fallthrough]]
                    case SDL_KEYDOWN:
                        key_out.push_back(hid2ps2_2[e.key.keysym.scancode]);
                        break;
                }
            }
            SDL_RenderPresent(renderer);
        }

        // Advance clock
        trace.advance();
        step();
    }
    // SDL_DestroyTexture(char_texture);
    // SDL_FreeSurface(surf);
    // SDL_DestroyRenderer(renderer);
    // SDL_DestroyWindow(window);
}