#!/bin/bash
#TARGET=armv6j-unknown-linux-gnueabihf
#TARGET=armv7a-hardfloat-linux-gnueabi
#TARGET=armv7a-unknown-linux-gnueabihf
TARGET=aarch64-unknown-linux-gnu
#B=2.40-r9
B=2.41-r3
G=13.2.1_p20240113-r1
K=6.6
L=2.38-r10

nodist_path
FEATURES=" -distcc" crossdev --clean --target ${TARGET}
FEATURES=" -distcc" crossdev --b ${B} --g ${G} --k ${K} --l ${L} --target ${TARGET}
