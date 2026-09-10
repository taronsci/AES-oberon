# AES-oberon
Implementation of AES-128 in Oberon

To build the program you will need an Oberon compiler.  
I have used [VOC](https://github.com/vishapoberon/compiler) during development.  

## Building
1. Build modules for contants and xor
```
voc Constant.mod Xor.mod
```

2. Build main module
```
voc Aes.mod -m
```

## Usage

Run the help command to see the available options:
```
./Aes -h
```
Usage:
```
./Aes -h
./Aes (-e | -d) INPUT_FILE OUTPUT_FILE
```

## Examples

Encrypt a file:
```
./Aes -e plaintext.txt encrypted.txt
```
Decrypt a file:
```
./Aes -d encrypted.txt decrypted.txt
```

## Notes on implementation
### 1. Providing the key
- When you run the program you will be asked to provide a key. The key must contain exactly 16 printable ASCII characters.

### 2. Padding
- PKCS#7 padding is used.

### PKCS#7
PKCS#7 padding adds `N` bytes, where `N` is the number of bytes needed to reach the next 16-byte boundary. Each added byte has the value `N`.  

eg.  
if 3 bytes of padding are required, the padding is:
```text
03 03 03
```
if 5 bytes of padding are required, the padding is:
```text
05 05 05 05 05
```

If the input is already a multiple of 16 bytes, a full block (16) of `10` is added. During decryption, the final byte indicates the padding length, and the corresponding bytes are verified before being removed.

### 3. AES Mode

This implementation uses **AES in Electronic Codebook (ECB) mode**. The input is divided into 16-byte blocks, and each block is encrypted or decrypted independently using the same AES key.
