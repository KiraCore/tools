# BIP39 Mnemonic Generator

A command-line tool for generating BIP39-compliant mnemonic phrases. These mnemonic words can be used for creating and recovering deterministic wallets in the cryptocurrency ecosystem.

## Features

- Generate BIP39-compliant mnemonic phrases (12 to 768 words)
- Hybrid entropy system combining computer-generated and user-provided entropy via XOR
- Multiple entropy input formats (binary `0b...` and hexadecimal `0x...`)
- Cipher-based entropy extrapolation (SHA-256, SHA-512, padding)
- Verbose mode with detailed entropy breakdown
- Official BIP39 English wordlist with CRC32 integrity validation

## Installation

### From Source

```bash
git clone https://github.com/KiraCore/tools.git
cd tools/bip39gen
make install
```

### Docker Build

Build binary and .deb package using Docker:
```bash
# Build the image
docker build -t bip39gen-builder .

# Extract artifacts to ./dist
docker run --rm -v $(pwd)/dist:/dist bip39gen-builder sh -c "cp /output/* /dist/"
```

The output includes:
- `bip39gen` - standalone binary
- `bip39gen-linux-amd64.deb` - Debian package

Cross-compile for different architectures:
```bash
# Build for ARM64
docker build --platform linux/arm64 -t bip39gen-builder-arm64 .
```

### Quick-Install bash-utils

```bash
FILE_NAME="bash-utils.sh" && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}" -O ./$FILE_NAME && \
 chmod -v 555 ./$FILE_NAME && ./$FILE_NAME bashUtilsSetup "/var/kiraglob" && . /etc/profile && \
 echoInfo "INFO: Installed bash-utils $(bash-utils bashUtilsVersion)"
```

### Install Platform-Specific Binary

```bash
safeWget ./bip39gen.deb \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/bip39gen-$(getPlatform)-$(getArch).deb" \
 "QmeqFDLGfwoWgCy2ZEFXerVC5XW8c5xgRyhK5bLArBr2ue" && rm -rfv ./bip39gen && \
 dpkg-deb -x ./bip39gen.deb ./bip39gen && cp -fv ./bip39gen/bin/bip39gen /usr/local/bin/bip39gen && \
 chmod +x "/usr/local/bin/bip39gen" && rm -rfv ./bip39gen ./bip39gen.deb
```

## Usage

```bash
bip39gen [COMMAND] [OPTIONS]
```

### Commands

| Command    | Description                          |
|------------|--------------------------------------|
| `mnemonic` | Generate BIP39 mnemonic words        |
| `version`  | Display the current tool version     |

### Options for `mnemonic` Command

| Flag             | Short | Type    | Default | Description                                                |
|------------------|-------|---------|---------|------------------------------------------------------------|
| `--length`       | `-l`  | int     | 24      | Number of mnemonic words (must be divisible by 3, max 768) |
| `--entropy`      | `-e`  | string  | ""      | User entropy to mix with computer-generated entropy        |
| `--raw-entropy`  | `-r`  | string  | ""      | Pre-existing entropy to regenerate mnemonics from          |
| `--cipher`       | `-c`  | string  | ""      | Cipher for entropy extrapolation: `sha256`, `sha512`, `padding` |
| `--hex`          |       | boolean | false   | Interpret input as hexadecimal format                      |
| `--verbose`      | `-v`  | boolean | false   | Enable verbose output with entropy breakdown               |

### Entropy Calculation

The relationship between word count and entropy bits:

| Words | Entropy Bits | Checksum Bits |
|-------|--------------|---------------|
| 12    | 128          | 4             |
| 15    | 160          | 5             |
| 18    | 192          | 6             |
| 21    | 224          | 7             |
| 24    | 256          | 8             |
| 48    | 512          | 16            |

**Formula:** `Entropy Bits = (words / 3) * 32` and `Checksum Bits = Entropy Bits / 32`

### Ciphers

| Cipher    | Description                                                                 |
|-----------|-----------------------------------------------------------------------------|
| `sha256`  | Hash input entropy with SHA-256, produces 256-bit entropy (24-word mnemonic) |
| `sha512`  | Hash input entropy with SHA-512, produces 512-bit entropy (48-word mnemonic) |
| `padding` | Pad insufficient entropy with zeros to reach required length                |

## Examples

### Basic Usage

Generate a 24-word mnemonic (default):
```bash
bip39gen mnemonic
```

Generate a 12-word mnemonic:
```bash
bip39gen mnemonic --length 12
```

Check version:
```bash
bip39gen version
```

### Verbose Output

Generate with detailed entropy breakdown:
```bash
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

### User-Provided Entropy

Mix user entropy with computer-generated entropy:
```bash
bip39gen mnemonic --entropy "your_entropy_here"
```

With SHA-256 cipher for deterministic 24-word output:
```bash
bip39gen mnemonic --entropy "your_passphrase" --cipher sha256
```

With SHA-512 cipher for deterministic 48-word output:
```bash
bip39gen mnemonic --entropy "your_passphrase" --cipher sha512 --length 48
```

### Raw Entropy

Regenerate mnemonic from existing entropy (hexadecimal):
```bash
bip39gen mnemonic --hex=true --raw-entropy="0xacb5e5e6e31f4a122723da97e1404c28b331e643e9aa2dc4d3c1d1be50ce3264"
```

Regenerate from binary entropy:
```bash
bip39gen mnemonic --raw-entropy="0b10101100101101...."
```

With padding for insufficient entropy:
```bash
bip39gen mnemonic --raw-entropy="10101100101101" --cipher padding
```

## How Entropy Mixing Works

The tool uses a hybrid entropy system for enhanced security:

1. **Computer Entropy**: Cryptographically secure random bytes from `crypto/rand`
2. **User Entropy**: Optional input provided via `--entropy` flag
3. **XOR Operation**: Both sources are combined using XOR, ensuring security even if one source is weak

In verbose mode, each word shows the XOR operation:
```
COMPUTER       HUMAN          BIN        DEC   BIP39 WORD
00010101001 ⊕ 00000000000 = 00010101001 -> 169 -> benefit
```

## Security

- Uses cryptographically secure random generation via Go's `crypto/rand`
- BIP39 wordlist integrity verified on startup (CRC32 checksum: `c1dbd296`)
- Each word maps to an 11-bit index (2^11 = 2048 words in the BIP39 wordlist)
- Comprehensive test vectors for validation

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on [GitHub](https://github.com/KiraCore/tools).
