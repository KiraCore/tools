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
python3 ./tmkms-key-import.py "$1" "$2" "$3" "$4" "$5"
```

`$1` : mnemonic

`$2` : `private validator key` out file path

`$3` : secret `KMS key` out file path

`$4` : `node key` out file path

`$5` : `node id` out file path
