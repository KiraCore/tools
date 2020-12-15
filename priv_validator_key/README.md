# Private Validator Key Generator

## Install

```bash
make install
```
It will create a binary `priv_validator_key` in go path.

## How to use

1. Run generator.

```bash
make install
priv_validator_key
```

or

```bash
make start
```

2. Input Mnemonic

For example
```
Enter Mnemonic: swap exercise equip shoot mad inside floor wheel loan visual stereo build frozen always bulb naive subway foster marine erosion shuffle flee action there
```

3. Input path to save `priv_validator_key.json`

For example
```
Enter path to save priv_validator_key.json: ./
```

Default will path will be `./`.

4. `priv_validator_key.json` will be created in the specified folder.
