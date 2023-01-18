## Mnemonics Generator

KIRA `bip39gen` is an independent CLI tool, allowing for generation of mnemonics with external, user provided entropy as well as known entropy which can be provided as string or hex (specify --hex flag). Opposed to other mnemonic generators this tool provides explicit, human readable proof of the correct key generation and mixing with the human provided entropy (if such is specified).

### Use example

```bash
> bip39gen mnemonic --verbose=true --length=12

# Example Output:
============================================================================================
            Mnemonic words: 12
              Entropy Bits: 128
             Checksum Bits: 4
    Computer Entropy (hex): 2ed62aeb8226969bfff1e071b5e0e64e
       Human Entropy (hex): 00000000000000000000000000000000
   Resulting Entropy (hex): 2ed62aeb8226969bfff1e071b5e0e64e
Resulting Entropy (SHA256): 125fe244b84ae0a99c9a82270b335b17c899711804959912b4b0178d5128d1ba
  Resulting Checksum (bin): 0001
============================================================================================
NR.       COMPUTER       HUMAN          BIN        DEC   BIP39 WORD
1.      00101110110 ⊕ 00000000000 = 00101110110 -> 374   -> conduct
2.      10110001010 ⊕ 00000000000 = 10110001010 -> 1418  -> rally
3.      10111010111 ⊕ 00000000000 = 10111010111 -> 1495  -> road
4.      00000100010 ⊕ 00000000000 = 00000100010 -> 34    -> affair
5.      01101001011 ⊕ 00000000000 = 01101001011 -> 843   -> harvest
6.      01001101111 ⊕ 00000000000 = 01001101111 -> 623   -> evil
7.      11111111110 ⊕ 00000000000 = 11111111110 -> 2046  -> zone
8.      00111100000 ⊕ 00000000000 = 00111100000 -> 480   -> despair
9.      01110001101 ⊕ 00000000000 = 01110001101 -> 909   -> immune
10.     10101111000 ⊕ 00000000000 = 10101111000 -> 1400  -> pyramid
11.     00111001100 ⊕ 00000000000 = 00111001100 -> 460   -> define
12.     10011100001 ⊕ 00000000000 = 10011100001 -> 1249  -> order
============================================================================================
Mnemonic words:
conduct rally road affair harvest evil zone despair immune pyramid define order
```

### Setup from binary file

```bash
TOOLS_VERSION="v0.3.0"

# Quick-Install bash-utils or see root repository README file for secure download
FILE_NAME="bash-utils.sh" && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}" -O ./$FILE_NAME && \
 chmod -v 555 ./$FILE_NAME && ./$FILE_NAME bashUtilsSetup "/var/kiraglob" && . /etc/profile && \
 echoInfo "INFO: Installed bash-utils $(bash-utils bashUtilsVersion)"

# Install bip39gen for platform specific system & verify signature file
safeWget ./bip39gen.deb \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/bip39gen-$(getPlatform)-$(getArch).deb" \
 "QmeqFDLGfwoWgCy2ZEFXerVC5XW8c5xgRyhK5bLArBr2ue" && rm -rfv ./bip39gen && \
 dpkg-deb -x ./bip39gen.deb ./bip39gen && cp -fv ./bip39gen/bin/bip39gen /usr/local/bin/bip39gen && \
 chmod +x "/usr/local/bin/bip39gen" && rm -rfv ./bip39gen ./bip39gen.deb
```