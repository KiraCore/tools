## Mnemonics Generator

KIRA `bip39gen` CLI tool based on [go-bip39](https://github.com/tyler-smith) library, allowing for generation of mnemonics with external, user provided entropy. If no external entropy is provided then default entropy provided by the `bip39` lib rng gets mixed (XOR'ed) with SHA256 of the UUID for some extra security :)

### Example

```bash
bip39gen mnemonic --verbose=true --length=24 --entropy="user provided extra entropy"
```