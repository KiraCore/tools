# Private Validator Key Generator

Validator Key Generator is a CLI tool that generates validator keys, node keys, and NodeID files for the Cosmos SDK. The tool uses a BIP39 mnemonic to derive the keys and allows users to set custom Bech32 prefixes and BIP44 paths.

### Setup from binary file

```bash
TOOLS_VERSION="v0.3.47"

# Quick-Install bash-utils or see root repository README file for secure download
FILE_NAME="bash-utils.sh" && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}" -O ./$FILE_NAME && \
 chmod -v 555 ./$FILE_NAME && ./$FILE_NAME bashUtilsSetup "/var/kiraglob" && . /etc/profile && \
 echoInfo "INFO: Installed bash-utils $(bash-utils bashUtilsVersion)"

# Install validator-key-gen for platform specific system & verify signature file
safeWget ./validator-key-gen.deb \
 "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/validator-key-gen-$(getPlatform)-$(getArch).deb" \
 "QmeqFDLGfwoWgCy2ZEFXerVC5XW8c5xgRyhK5bLArBr2ue" && rm -rfv ./validator-key-gen && \
 dpkg-deb -x ./validator-key-gen.deb ./validator-key-gen && cp -fv ./validator-key-gen/bin/validator-key-gen /usr/local/bin/validator-key-gen && \
 chmod +x "/usr/local/bin/validator-key-gen" && rm -rfv ./validator-key-gen ./validator-key-gen.deb

# Check validator-key-gen version
validator-key-gen --version
```
### Installation

To install the Validator Key Generator, clone the repository and run make install:

```bash
git clone https://github.com/KiraCore/tools.git
cd tools/validator-key-gen
make install
```
### Usage

The Validator Key Generator can be used with the following command-line options:

```bash
validator-key-gen --mnemonic="your mnemonic phrase" [OPTIONS]
```

### Options

- -mnemonic:      A valid BIP39 mnemonic (required)
- -valkey:        Path to save the validator key JSON file
- -nodekey:       Path to save the node key JSON file
- -keyid:         Path to save the NodeID file
- -masterkeys     Path to save mnemonics.env, validator key, node key, node id files. Only works with -master flag 
- -master  	   If true, generate whole mnemonic set
- -accadr:        If true, output the account address
- -valadr:        If true, output the validator address
- -consadr:       If true, output the consensus address
- -prefix:        Set the Bech32 prefix (default: "kira")
- -path:          Set the BIP44 derivation path (default: "44'/118'/0'/0/0")

### Examples

1. Generate validator, node keys, and NodeID files:

```bash
validator-key-gen --mnemonic="your mnemonic phrase" --valkey="validator_key.json" --nodekey="node_key.json" --keyid="node_id.txt"
```

2. Generate whole mnemonic set from Master mnemonic
   
```bash
 validator-key-gen  --mnemonic="your mnemonic phrase" --masterkeys="path to folder" --master 
```
 
3. Output the account, validator, and consensus addresses:

```bash
validator-key-gen --mnemonic="your mnemonic phrase" --accadr --valadr --consadr
```

4. Customize the Bech32 prefix and BIP44 derivation path:

```bash
validator-key-gen --mnemonic="your mnemonic phrase" --prefix="custom_prefix" --path="44'/12345'/0'/0/0"
```
5. Version
```bash
validator-key-gen --version
```

### Contributing
If you would like to contribute to this project, please submit bug reports, feature requests, and pull requests on the repository.

### License
This project is licensed under the Apache License.