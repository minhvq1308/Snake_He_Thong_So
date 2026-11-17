#!/usr/bin/env python3
"""firmware.bin -> firmware.hex (mỗi dòng 1 từ 32-bit little-endian, đúng định dạng $readmemh của soc_memory.v)
Dùng:  python3 makehex.py firmware.bin 4096 > firmware.hex
"""
import sys

binfile, nwords = sys.argv[1], int(sys.argv[2])
data = open(binfile, "rb").read()
data += b"\x00" * ((-len(data)) % 4)
if len(data) > 4 * nwords:
    sys.exit("ERROR: firmware %d byte > bo nho %d byte" % (len(data), 4 * nwords))

for i in range(nwords):
    if 4 * i < len(data):
        w = data[4 * i: 4 * i + 4]
        print("%02x%02x%02x%02x" % (w[3], w[2], w[1], w[0]))
    else:
        print("00000000")
