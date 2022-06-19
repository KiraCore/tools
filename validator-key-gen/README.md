# Private Validator Key Generator

## Install

```bash
go build
make install
ln -s ./validator-key-gen /bin/validator-key-gen
```

## How to use

```bash
validator-key-gen --mnemonic="mnemonic here" --valkey="private validator key path here" --nodekey="node key path here" --keyid="node id path here"
```

E.g.
```bash
validator-key-gen --mnemonic="swap exercise equip shoot mad inside floor wheel loan visual stereo build frozen always bulb naive subway foster marine erosion shuffle flee action there" --valkey=./priv_validator_key.json --nodekey=./node_key.json --keyid=./node_id.key
```
