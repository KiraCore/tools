Features:
* added color printing commands `echoNC, echoC, echoPop, echoLog` including color store & restore
* `bash-utils` now installs `cosign` during setup if it's not already installed
* `safeWget` support for public key hosting on IPFS
* added `isCIRD` validation
* added `isWSL` command allowing to identify OS running within WSL
* added `ipfsGet` command allowing fetch from public gateways
* improved `isMnemonic` false positive detection rate
* added string manipulation commands: `strFixL, strFixR, strFixC, strRepeat, strShortN, strShort`
* `pressToContinue` now supports custom glob values
* bash utils can now be called with a command `bu`
* improved readme with download example for `bip39gen`
* added network interface commands: `getNetworkIface, getNetworkIfaces, getLocalIp, getPublicIp`