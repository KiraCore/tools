# KMS Private Key Import From Mnemonic

## Install

```bash
apt-get install -y python python3 python3-pip

pip3 install ECPy

cd $HOME

git clone https://github.com/KiraCore/tools.git

cd $HOME/tools/tmkms-key-import
/tools/tmkms-key-import

```
## How to use

```bash
python3 ./tmkms-key-import.py "$1" "$2" "$3" "$4" "$5" "$6"
```

`$1` : mnemonic for `private validator key`

`$2` : `private validator key` out file path

`$3` : secret `KMS key` out file path

`$4` : mnemonic for `node key`

`$5` : `node key` out file path

`$6` : `node id` out file path
