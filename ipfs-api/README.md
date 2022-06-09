![IPFS]https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/ipfs/ipfs.png)
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

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/KiraCore/tools

## Authors

* **Yevhen Yakubovskiyi** - *Initial work* - [MrLutik](https://github.com/mrlutik)
























/tags). 

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc.
