#Converts PAiA 8700 tape dumps to binary
# accepts mono, 8-bit, 44.1KHz wav
# Zack Nelson 2020
import struct, os
from sys import argv

try:
    len(argv[1])
except IndexError:
    print("Input file needed")
    exit(2)

fi = open(argv[1],'rb') #open input
fo = open(os.path.splitext(argv[1])[0]+".bin", 'wb+') #open output

file = fi.read()
fi.close()
buf = []

tone_length = 0 #time spent oscillating
dead_time = 0 #time not oscillating
starting_bits = 0

bit_count = 0
out_byte = 0
checksum = 0

for byte in file:
    if byte > 160 or byte < 90: # oscillating
        tone_length += 1
        dead_time = 0
    else: # dead space
        dead_time += 1
        if dead_time > 150: #~4ms dead space between bits
            starting_bits += 1

            if starting_bits > 255: #255 starting bits
                out_byte <<= 1        #logic 0 = 8 cycles of 2KHz
                if tone_length > 220: #logic 1 = 16 cycles of 2KHz
                    out_byte += 1
                    
                bit_count += 1
                if bit_count > 9:
                    buf.append(out_byte & 0xff)
                    if len(buf) > 1: #skip Ident for checksum
                        checksum += out_byte
                    out_byte = 0
                    bit_count = 0
            tone_length = 0
            dead_time = 0
                
print("Identifier: " + str(hex(buf[0])))
last_byte = buf[len(buf)-1]
checksum -= last_byte
if last_byte == (checksum & 0xFF):
    print("Checksum matched")
else:
    print("Checksum calculated: " + str(hex(checksum & 0xFF)))
    print("Checksum received: " + str(hex(last_byte)))
buf = buf[1:(len(buf)-1)] #trim index and checksum bytes

fo.write(struct.pack('B'*len(buf), *buf))
fo.close()
