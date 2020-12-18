#!/bin/bash
set +e && source "/etc/profile" &>/dev/null && set -e

PRIV_MNEMONIC=$1
PRIV_VALIDATOR_KEY_OUT=$2
SECRET__KMS_KEY_OUT=$3
NODE_MNEMONIC=$4
NODE_KEY_OUT=$5
NODE_ID_OUT=$6

[ -z "$PRIV_MNEMONIC" ] && PRIV_MNEMONIC=$(hd-wallet-derive --gen-words=24 --gen-key --format=jsonpretty -g | jq '.[0].mnemonic')
[ -z "$PRIV_VALIDATOR_KEY_OUT" ] && PRIV_VALIDATOR_KEY_OUT="$PWD/priv_validator_key.json"
[ -z "$SECRET__KMS_KEY_OUT" ] && SECRET__KMS_KEY_OUT="$PWD/signing.key"

[ -z "$NODE_MNEMONIC" ] && NODE_MNEMONIC=$(hd-wallet-derive --gen-words=24 --gen-key --format=jsonpretty -g | jq '.[0].mnemonic')
[ -z "$NODE_KEY_OUT" ] && NODE_KEY_OUT="$PWD/node_key.json"
[ -z "$NODE_ID_OUT" ] && NODE_ID_OUT="$PWD/node_id.json"

python3 /home/$SUDO_USER/tools/tmkms-key-import/tmkms-key-import.py "$1" "$2" "$3" "$4" "$5" "$6"