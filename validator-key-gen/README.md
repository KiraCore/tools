# Private Validator Key Generator

### Local Build

```bash
go build
make install
ln -s ./validator-key-gen /bin/validator-key-gen
```

### Setup from binary file

```bash
TOOLS_VERSION="v0.3.0"

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

### How to use

```bash
validator-key-gen --mnemonic="mnemonic here" --valkey="private validator key path here" --nodekey="node key path here" --keyid="node id path here"
```

E.g.
```bash
validator-key-gen --mnemonic="swap exercise equip shoot mad inside floor wheel loan visual stereo build frozen always bulb naive subway foster marine erosion shuffle flee action there" --valkey=./priv_validator_key.json --nodekey=./node_key.json --keyid=./node_id.key
```


