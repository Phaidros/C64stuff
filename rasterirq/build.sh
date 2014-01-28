#!/bin/sh
ca65 -t c64 -o rasterirq.o -W1 rasterirq.s
cl65 rasterirq.o --target c64 -o rasterirq

