# Bip39 Mnemonic Generator

The Bip39 Mnemonic Generator is a command-line tool that generates mnemonic words based on the BIP39 standard. These mnemonic words can be used for creating and recovering deterministic wallets in the cryptocurrency ecosystem.

### Installation

To install the Bip39 Mnemonic Generator, clone the repository, and build the project. Make sure you have the required dependencies installed.

```bash
git clone https://github.com/KiraCore/tools.git
cd tools/bip39gen
make install
```

#### Quick-Install bash-utils or see root repository README file for secure download
FILE_NAME="bash-utils.sh" && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}" -O ./$FILE_NAME && \
 chmod -v 555 ./$FILE_NAME && ./$FILE_NAME bashUtilsSetup "/var/kiraglob" && . /etc/profile && \
 echoInfo "INFO: Installed bash-utils $(bash-utils bashUtilsVersion)"

#### Install bip39gen for platform specific system & verify signature file
safeWget ./bip39gen.deb \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/bip39gen-$(getPlatform)-$(getArch).deb" \
 "QmeqFDLGfwoWgCy2ZEFXerVC5XW8c5xgRyhK5bLArBr2ue" && rm -rfv ./bip39gen && \
 dpkg-deb -x ./bip39gen.deb ./bip39gen && cp -fv ./bip39gen/bin/bip39gen /usr/local/bin/bip39gen && \
 chmod +x "/usr/local/bin/bip39gen" && rm -rfv ./bip39gen ./bip39gen.deb


### Usage

To use the Bip39 Mnemonic Generator, execute the tool with the desired options and flags. The following commands and flags are available:

#### Commands

- mnemonic: Generate mnemonic words
- version: Check the current version of the tool

#### Flags
- -length (-l):       Specify the number of mnemonic words to generate (default: 24)
- -entropy (-e):      Provide entropy for mixing and generating new mnemonic sentences
- -raw-entropy (-r):  Provide entropy to regenerate mnemonic sentences from
- -cipher (-c):       Choose a cipher to generate mnemonics. Available options are: sha256, sha512, chacha20, padding
- -hex:               Set hexadecimal string format for input
- -verbose (-v):      Set the verbose level of output

The tool checks for input validity, including length, entropy, and hex format. It also supports generating mnemonic words using different ciphers, such as SHA-256, SHA-512, and ChaCha20.

### Examples

Generate a new 24-word mnemonic:

```bash
bip39gen mnemonic
```

Generate a new 12-word mnemonic:

```bash
bip39gen mnemonic --length 12
```

Generate a new 24 word mnemonic with verbal output:

```bash
In: 
bip39gen mnemonic -v

Output:
============================================================================================
            Mnemonic words: 24
              Entropy Bits: 256
             Checksum Bits: 8
    Computer Entropy (hex): 1534daeb973c027ddc393ec64767d9794ae57f5b63c36e60c8f25c7bb41dc25b
       Human Entropy (hex): 0000000000000000000000000000000000000000000000000000000000000000
   Resulting Entropy (hex): 1534daeb973c027ddc393ec64767d9794ae57f5b63c36e60c8f25c7bb41dc25b
Resulting Entropy (SHA256): 19315d8c10a010bdc2142820498c1c35f55e487d2d09f8caefe28f8f93ea0fe4
  Resulting Checksum (bin): 00011001
============================================================================================
NR.       COMPUTER       HUMAN          BIN        DEC   BIP39 WORD
1.      00010101001 ⊕ 00000000000 = 00010101001 -> 169   -> benefit
2.      10100110110 ⊕ 00000000000 = 10100110110 -> 1334  -> plug
3.      10111010111 ⊕ 00000000000 = 10111010111 -> 1495  -> road
4.      00101110011 ⊕ 00000000000 = 00101110011 -> 371   -> common
5.      11000000001 ⊕ 00000000000 = 11000000001 -> 1537  -> scan
6.      00111110111 ⊕ 00000000000 = 00111110111 -> 503   -> discover
7.      01110000111 ⊕ 00000000000 = 01110000111 -> 903   -> ill
8.      00100111110 ⊕ 00000000000 = 00100111110 -> 318   -> chief
9.      11000110010 ⊕ 00000000000 = 11000110010 -> 1586  -> shock
10.     00111011001 ⊕ 00000000000 = 00111011001 -> 473   -> depth
11.     11110110010 ⊕ 00000000000 = 11110110010 -> 1970  -> wagon
12.     11110010100 ⊕ 00000000000 = 11110010100 -> 1940  -> verb
13.     10101110010 ⊕ 00000000000 = 10101110010 -> 1394  -> purity
14.     10111111101 ⊕ 00000000000 = 10111111101 -> 1533  -> sausage
15.     01101101100 ⊕ 00000000000 = 01101101100 -> 876   -> horn
16.     01111000011 ⊕ 00000000000 = 01111000011 -> 963   -> journey
17.     01101110011 ⊕ 00000000000 = 01101110011 -> 883   -> hover
18.     00000110010 ⊕ 00000000000 = 00000110010 -> 50    -> alien
19.     00111100100 ⊕ 00000000000 = 00111100100 -> 484   -> develop
20.     10111000111 ⊕ 00000000000 = 10111000111 -> 1479  -> rib
21.     10111011010 ⊕ 00000000000 = 10111011010 -> 1498  -> robust
22.     00001110111 ⊕ 00000000000 = 00001110111 -> 119   -> auction
23.     00001001011 ⊕ 00000000000 = 00001001011 -> 75    -> annual
24.     01100011001 ⊕ 00000000000 = 01100011001 -> 793   -> glimpse
============================================================================================
Mnemonic words: 
benefit plug road common scan discover ill chief shock depth wagon verb purity sausage horn journey hover alien develop rib robust auction annual glimpse
```

Generate a mnemonic using user-provided entropy:

```bash
bip39gen mnemonic --entropy "your_entropy_here"
```

Generate a mnemonic using raw entropy:

```bash
bip39gen mnemonic --raw-entropy "your_raw_entropy_here"
```
Generate a mnemonic using user-provided or human entropy in format "0x.." or "0b..". If hex is provided the flag should be set explicitly: 

```bash
bip39gen mnemonic --hex=true --raw-entropy="0xacb5e5e6e31f4a122723da97e1404c28b331e643e9aa2dc4d3c1d1be50ce3264"
```

```bash
bip39gen mnemonic --raw-entropy="0b10101100101101...."
```

Use a specific cipher to generate mnemonics:

```bash
bip39gen mnemonic --cipher sha256
```

### Contributing

Contributions are welcome! If you'd like to report bugs or suggest improvements, please open an issue or submit a pull request.

