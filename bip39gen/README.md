## Mnemonics Generator

KIRA `bip39saifu` independent CLI tool, allowing for generation of mnemonics with external, user provided entropy as well as known entropy which can be provided as a bit string.

### Example

```bash
bip39gen mnemonic --verbose=true --length=24 --entropy="user provided extra entropy"
```