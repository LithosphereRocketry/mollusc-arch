/**
 * Simple, not-too-bright tool to convert character map PNG files to ASCII hex
 * files for use in Verilog.
 * 
 * Usage: png2hex <input png file> <output hex file>
 * 
 * The input png file must have a width which is a multiple of 8 and height
 * which is a multiple of 16; it should be divided into glyphs where each glyph
 * occupies an 8x16-pixel region. Any pixels in a glyph that are pure black
 * will be translated to 1; all others will be translated to 0.
 * 
 * Output is in the form of newline-separated, 128-bit hex strings, formatted
 * as contiguous numbers. Each one corresponds to a glyph, with the spritesheet
 * scanned in left-to-right, top-to-bottom order. Similarly, the place value of
 * each bit represents its position in the image, scanned left to right, top to
 * bottom - i.e. the LSB of the provided 128-bit integer represents the top left
 * pixel, and the MSB represents the bottom right.
 * 
 * This code draws partially from the minimal libpng example by Guillaume
 * Cottenceau, which is used under the X11 license.
*/

#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <png.h>

bool ispng(FILE* f) {
    char hdrbuf[8];
    fread(hdrbuf, 1, 8, f);
    fseek(f, -8, SEEK_CUR);
    return !png_sig_cmp(hdrbuf, 0, 8);
}

bool ispresent(const png_byte* px, int colortype) {
    if(colortype & PNG_COLOR_MASK_COLOR) {
        return px[0] == 0 && px[1] == 0 && px[2] == 0;
    } else {
        return px[0] == 0;
    }
}

int main(int argc, char** argv) {
    if(argc != 3) {
        printf("%s <png> <hex out>\n", argv[0]);
        return -1;
    }

    FILE* imfile = fopen(argv[1], "rb");
    if(!imfile) {
        printf("error: file not found: %s\n", argv[1]);
        return -1;
    }

    // TODO: this doesn't memory leak because it immediately dies but if it were
    // wrapped in a larger program it would; libpng's free commands are weird
    // and confusing
    if(!ispng(imfile)) {
        printf("error: %s is not a PNG file\n", argv[1]);
        return -1;
    }

    png_struct* pngptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    png_info* infoptr = png_create_info_struct(pngptr);
    png_init_io(pngptr, imfile);
    png_read_info(pngptr, infoptr);

    // ewwww
    if (setjmp(png_jmpbuf(pngptr))) {
        printf("error: failed to read png file\n");
        return -1;
    }

    unsigned int width = png_get_image_width(pngptr, infoptr);
    unsigned int height = png_get_image_height(pngptr, infoptr);

    png_byte** row_ptrs = (png_byte**) malloc(sizeof(png_byte*) * height);
    unsigned int rowbytes = png_get_rowbytes(pngptr, infoptr);
    unsigned int pxbytes = rowbytes/width;
    for(unsigned int y = 0; y < height; y++) {
        row_ptrs[y] = (png_byte*) malloc(rowbytes);
    }
    png_read_image(pngptr, row_ptrs);
    fclose(imfile);

    FILE* hexfile = fopen(argv[2], "w");
    if(!hexfile) {
        printf("Failed to open output file: %s\n", argv[2]);
        return -1;
    }

    for(unsigned int i = 0; i < height; i += 16) {
        for(unsigned int j = 0; j < width; j += 8) {
            uint64_t upperhalf = 0;
            uint64_t lowerhalf = 0;
            for(int c = 0; c < 8; c++) {
                for(int r = 0; r < 8; r++) {
                    if(ispresent(row_ptrs[i + r] + ((j + c)*pxbytes),
                            png_get_color_type(pngptr, infoptr))) {
                        upperhalf |= (1ul << (r*8 + c));
                    }
                    if(ispresent(row_ptrs[i + r + 8] + ((j + c)*pxbytes),
                            png_get_color_type(pngptr, infoptr))) {
                        lowerhalf |= (1ul << (r*8 + c));
                    }
                }       
            }
            fprintf(hexfile, "%016lx%016lx\n", lowerhalf, upperhalf);
        }
    }
    fclose(hexfile);
}