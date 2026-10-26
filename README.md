# Huffman-Compression-in-Assembly

A command-line Huffman encoder and decoder written in x86 assembly. It compresses any file using Huffman coding based on byte-frequency analysis, and restores the original file, including its extension, when decompressing.

**Architecture:** x86-32 (32-bit Windows executable)
**Assembler:** NASM

## Features

- Byte-level Huffman encoding and decoding that works on any file type
- Compressed files begin with a magic number (`HUFF`): the program refuses to decode other files and refuses to re-encode its own output
- The original file extension is stored inside the compressed file, so decoding restores the original file name
- A dedicated end-of-file (EOF) symbol marks where the data ends, so the zero padding in the last byte is never mistaken for data

## Build

Requires NASM and the nlink linker with the mio, io and util libraries.

```
nasm -f win32 Project.asm
nlink Project.obj -lutil -lmio -lio -o p.exe
```

## Usage

```
p "path\to\file.txt" c      compress
p "path\to\file.huff" d     decompress
```

Compressing `file.txt` produces `file.huff` in the same folder. The original extension is replaced by `.huff` in the file name and saved inside the file. Decompressing `file.huff` recreates `file.txt` from the stored extension. The program prints a short progress message for each stage and `ok` when it finishes.

## How it works

1. **Count frequencies.** Count how often each byte value occurs, and add one EOF symbol with frequency 1.
2. **Build the tree.** Repeatedly merge the two lowest-frequency nodes until one root remains. Nodes are kept in an array of 16-byte records (frequency, symbol, left child, right child).
3. **Derive the codes.** Walk the tree to give every symbol a bit code, so frequent bytes get short codes.
4. **Write the output.** Write the header (see below), then each byte's code packed into bytes, then the EOF code, padded with zero bits to a whole byte.
5. **Decode.** Read the header, rebuild the identical tree from the stored frequency table, and follow the bits through the tree, writing a byte at each leaf until the EOF symbol is reached.

## File format

All multi-byte numbers are little-endian.

| Offset | Size | Field | Description |
|---|---|---|---|
| `0x000` | 4 bytes | Magic number | `HUFF`, identifies files created by this program |
| `0x004` | 1028 bytes | Frequency table | 257 32-bit counts: byte values 0 to 255, then the EOF symbol (always 1) |
| `0x408` | 4 bytes | Original size | Size of the uncompressed file in bytes |
| `0x40C` | 10 bytes | File type | Original file extension, zero-padded |
| `0x416` | variable | Encoded bitstream | Huffman codes packed most significant bit first, ending with the EOF code and zero padding |

The header is a fixed 1,046 bytes.

## Error handling

| Condition | Message |
|---|---|
| Decoding a file that does not start with the `HUFF` magic number | `The given file is not a .huff file` |
| Encoding a file that starts with the `HUFF` magic number | `The given file is a .huff file and it cannot be encoded` |

Error handling is otherwise minimal; see Known limitations.

## Testing

The program was tested on 14 files from the Canterbury Corpus and its Artificial set (listed below), including edge cases such as a one-byte file (`a.txt`), a single repeated symbol (`aaa.txt`) and random characters (`random.txt`).

## Benchmarks

Ratio is compressed size divided by original size, so lower is better. Sizes are in bytes and include the fixed 1,046-byte header.

| File | Content | Original | Compressed | Ratio |
|---|---|---|---|---|
| alice29.txt | English prose | 152,089 | 88,736 | 0.583 |
| asyoulik.txt | Shakespeare play | 125,179 | 76,855 | 0.614 |
| lcet10.txt | Technical writing | 426,754 | 251,613 | 0.590 |
| plrabn12.txt | Poetry | 481,861 | 276,634 | 0.574 |
| cp.html | HTML | 24,603 | 17,247 | 0.701 |
| fields.c | C source code | 11,150 | 8,074 | 0.724 |
| grammar.lsp | Small Lisp source file | 3,721 | 3,218 | 0.865 |
| kennedy.xls | Excel spreadsheet | 1,029,744 | 463,609 | 0.450 |
| ptt5 | Fax bitmap | 513,216 | 107,600 | 0.210 |
| sum | Executable | 38,240 | 26,693 | 0.698 |
| a.txt | One byte | 1 | 1,047 | 1047 |
| aaa.txt | One repeated byte | 100,000 | 13,547 | 0.135 |
| alphabeth.txt | Repeating alphabet | 100,000 | 61,143 | 0.611 |
| random.txt | Random characters (64-symbol alphabet) | 100,000 | 76,231 | 0.762 |

### Observations

- **Text and source code** compress to roughly 58% to 72% of their size, which is about 4.6 to 5.3 bits per byte. Huffman coding only uses how often each byte occurs, not repeated words or phrases.
- **One bit per symbol is the floor.** `aaa.txt` holds 100,000 identical bytes yet compresses to 13,547 bytes, because every symbol still costs at least one bit: 12,501 bytes of data plus the header.
- **The header hurts small files.** The fixed 1,046-byte header grows `a.txt` from 1 byte to 1,047 bytes. For `grammar.lsp` the coded data alone would be 58% of the original, but the header lifts the ratio to 86.5%.

## Known limitations

- The whole input is read into a 100,000,000-byte buffer, so inputs are limited to about 100 MB
- File paths are limited to about 99 characters
- The fixed 1,046-byte header makes very small files larger after compression
- Files without an extension must be given with a trailing dot on the command line, for example p "ptt5." c. Windows treats ptt5. as ptt5, so the right file is opened, and the output is named ptt5.huff.

