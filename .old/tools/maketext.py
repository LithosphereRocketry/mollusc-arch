#!/usr/bin/python

text = "I realized, the moment I fell into the fissure, that the book would not be destroyed as I had planned. It continued falling into that starry expanse of which I had only a fleeting glimpse. I have tried to speculate where it might have landed, but I must admit, however- such conjecture is futile. Still, the question of whose hands might someday hold my Myst book are unsettling to me. I know that my apprehensions might never be allayed, and so I close, realizing that perhaps, the ending has not yet been written."

with open("build/myst.hex", "w") as f:
    for i in range(16384):
        f.write(f"{ord(text[i % len(text)]):x}\n")