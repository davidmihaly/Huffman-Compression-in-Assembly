# Huffman-Compression-in-Assembly

A command line Huffman encoder/decoder written in x86 assembly. Compresses files using Huffman coding based byte frequency analysis. 
Architecture: x86-32, Assembler: NASM

Features
Byte level Huffman encoding and decoding

Build:
nasm -f win32 Project.asm
nlink Project.obj  -lutil -lmio -lio -o p.exe

Usage:
p "filepath\file.txt" c		- compress
p "filepath\file.huff" d - decompress

Encodes file.txt and produces file.huff. The files original extension gets replaced by the .huff extension, but the original extension is saved in the file.

File Format:
x00 Magic Number 4 bytes Contains the HUFF identifyer
x04 Frequency table 1024 bytes Contains the frequency table
x?? OrigianalSize 4 bytes Stores the original size of the file
x?? FileType 10 bytes Stores the original extension of the file
x?? Encoded bitstream variables Stores the encripted data

Error Handling:
The program has minimal error handling:
Decoding a file without the HUFF magic number - The given file is not a .huff file
Encoding a file that has the HUFF magic number - The given file is a .huff file and it cannot be encoded

Testing

Benchmarks

x??
