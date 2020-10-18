#Converts binary file to PAiA 8700 tape dump format
# outputs 8KHz, 8bit, mono WAV
# Zack Nelson 2020
import struct, os
from sys import argv

#functions---------------------------------------------
def out_bit(bit):
    for x in range(8 *(bit+1)): # 8 pulses = 0, 16 = 1
        for y in range(2): # hi
            buf.append(0xD8)
        for y in range(2): # lo
            buf.append(0x28)

    for x in range(32): # 4 ms dead space
        buf.append(128) # null

def out_byte(byte):
    out_bit(0) #start bit
    for i in range(8):
        bit = bool(byte & (1<<7))
        byte <<= 1
        out_bit(bit)
    out_bit(1) #stop bit
#------------------------------------------------------
    
try:
    len(argv[1])
except IndexError:
    print("Input file needed")
    exit(2)

fi = open(argv[1],'rb') #open input
fo = open(os.path.splitext(argv[1])[0]+".wav", 'wb+') #open output

file = fi.read()
fi.close()
buf = []

checksum = 0

for i in range(256): #starting bits
    out_bit(1)

out_byte(1) #index byte

for byte in file: #output all bytes
    checksum += byte
    out_byte(byte)

out_byte(checksum) #output checksum

#add wave header
fo.write(str.encode("RIFF"))
fo.write((len(buf) + 36).to_bytes(4, byteorder='little')) #length in bytes
fo.write(str.encode("WAVE"))
fo.write(str.encode("fmt"))
fo.write(b'\x20') #null
fo.write((16).to_bytes(4, byteorder='little')) #Length of format data
fo.write((1).to_bytes(2, byteorder='little')) #PCM
fo.write((1).to_bytes(2, byteorder='little')) #Number of chans
fo.write((8000).to_bytes(4, byteorder='little')) #Sample Rate
fo.write((8000).to_bytes(4, byteorder='little')) #Sample Rate * bits * chans / 8
fo.write((1).to_bytes(2, byteorder='little')) #8bit mono
fo.write((8).to_bytes(2, byteorder='little')) #Bits per sample
fo.write(str.encode("data"))
fo.write(len(buf).to_bytes(4, byteorder='little')) #length in bytes

fo.write(struct.pack('B'*len(buf), *buf))
fo.close()
