# Private Validator Key Generator

## Install

```bash
go build
make install
ln -s ./priv-validator-key-gen /bin/priv-validator-key-gen
```

## How to use

```bash
priv-validator-key-gen --mnemonic="mnemonic here"
```

Will create json file in the current directory
```bash
priv_validator_key.json
```
