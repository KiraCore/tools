Features:
* added color printing commands `echoNC, echoC, echoPop, echoLog` including color store & restore
* `bash-utils` now installs `cosign` during setup if it's not already installed
* `safeWget` support for public key hosting on IPFS
* added `isCIDR` validation
* added `isWSL` command allowing to identify OS running within WSL
* added `ipfsGet` command allowing fetch from public gateways
* improved `isMnemonic` false positive detection rate
* added string manipulation commands: `strFixL, strFixR, strFixC, strRepeat, strShortN, strShort`
* `pressToContinue` now supports custom glob values
* bash utils can now be called with a command `bu`
* improved readme with download example for `bip39gen`
* added network interface commands: `getNetworkIface, getNetworkIfaces, getLocalIp, getPublicIp`
* added variable value grab commands: `getVar, tryGetVar` as well as non throwing setter `trySetVar`
* Allow empty variables in `getArgs`
* The `urlContentLength` and `urlExists` now correctly support binary files
* Support for empty values and silent mode with `getArgs`
* Json parser `jsonParse` now supports key sorting with `--sort-keys=<bool>`
* Added word capitalization function `toCapital`
* Support for optimistic argument resolving in `getArgs` with `--gargs_throw=<bool> --gargs_verbose=<bool>`