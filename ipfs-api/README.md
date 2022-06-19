# IPFS-API

The app to manipulate data whithin IPFS using pinata.cloud as node service provider.

## Getting Started

Get the repo from github.

`
git clone https://github.com/KiraCore/tools.git 
`

### Prerequisites

To build the app you need the golang to be preinstalled.

```
https://go.dev/doc/install
```

Check for updates and install building essentials
`
sudo apt update
sudo apt install build-essential
sudo apt upgrsde -y

`

### Installing

Check the latest branch. It should start from v ...

`
git branch -r | grep v0
`

Switch for the latest branch. 

`
git checkout origin/v0...
`

after this step just enter the ipfs-api directory  and execute:
`
make build
`
the executable will appear in the tools/ipfs-api/bin directory

Make sure it has an executable permission:
`
chmod +x tools/ipfs-api/bin/ipfs-api
`


```
Give the example
```

## Built With

* [Pinata.Cloud](https://docs.pinata.cloud/pinata-api) - The API v1. is used


## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags](https://github.com/KiraCore/tools/tags)

## Authors

* **Yevhen Yakubovskiyi** - *Initial work* - [MrLutik](https://github.com/mrlutik)