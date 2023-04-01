# IPFS-API

The app to manipulate data whithin IPFS using pinata.cloud as node service provider.

## Getting Started

Get the repo from github.

`
git clone https://github.com/KiraCore/tools.git 
`

### Installing

Installation script:

```
TOOLS_VERSION="v0.3.27" && rm -rfv /tmp/ipfs-api && \
 safeWget /tmp/ipfs-api.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/ipfs-api-$(getPlatform)-$(getArch).deb" "$KIRA_COSIGN_PUB" && \
 dpkg-deb -x /tmp/ipfs-api.deb /tmp/ipfs-api && cp -fv "/tmp/ipfs-api/bin/ipfs-api" /usr/local/bin/ipfs-api && chmod -v 755 /usr/local/bin/ipfs-api && \
 ipfs-api version
```

## Use

```bash
PINATA_API_JWT="***"

# pin folder or file
ipfs-api pin ./folder folder --key=$PINATA_API_JWT --verbose=true --force=true

# check if folder or file exists
ipfs-api pinned folder --key=$PINATA_API_JWT --verbose=true

# delete folder or file
ipfs-api delete folder --key=$PINATA_API_JWT --verbose=true
```

## Built With

* [Pinata.Cloud](https://docs.pinata.cloud/pinata-api) - The API v1. is used


## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags](https://github.com/KiraCore/tools/tags)

## Authors

* **Yevhen Yakubovskiyi** - *Initial work* - [MrLutik](https://github.com/mrlutik)