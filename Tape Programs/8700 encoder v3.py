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
    print("Parameters: file start-address identifier-byte")
    exit(2)

fi = open(argv[1],'rb') #open input
fo = open(os.path.splitext(argv[1])[0]+".wav", 'wb+') #open output

file = fi.read()
fi.close()
buf = []

checksum = 0
address = 0
if len(argv) > 2 and argv[2]: #parse starting address
    if argv[2].startswith("0x") == False:
        argv[2] = "0x" + argv[2]
    if int(argv[2], 0):
        address = int(argv[2], 0) & 0xFFFF
begAdr = address
endAdr = address + (len(file) -1)& 0xFFFF
print("Starting Address: " + str(hex(address)))
print("Ending Address: " + str(hex(endAdr)))
ident = 1
if len(argv) > 3 and argv[3]: #parse identifier
    ident = ident & 0xff
print("Identifier: " + str(hex(ident)))

for i in range(256): #starting bits
    out_bit(1)

out_byte(ident) #Identifier/index byte

for byte in file: #output all bytes
    #Zeropage programs must include running values for POTSHOT
    if address == 0xEE: #CHKSUM
        byte = checksum
    elif address == 0xEF: #STATUS
        byte = 0xFF
    elif address == 0xF0: #COMAND
        byte = 0xDD
    elif address == 0xF1: #IDENT
        byte = ident
    elif address == 0xF2: #ENDADR
        byte = endAdr & 0xFF
    elif address == 0xF3: #ENDADR hi
        byte = (endAdr >> 8) & 0xFF
    elif address == 0xF4: #BEGADR
        byte = begAdr & 0xFF
    elif address == 0xF5: #BEGADR hi
        byte = (begAdr >> 8) & 0xFF
    elif address == 0xF6: #PNTR
        byte = address & 0xFF
    elif address == 0xF7: #PNTR hi
        byte = (address >> 8) & 0xFF

    out_byte(byte)
    checksum += byte
    address += 1

out_byte(checksum) #output checksum
print("Checksum: " + str(hex(checksum & 0xFF)))

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
