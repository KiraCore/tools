# Quick Edit: FILE=$KIRA_WORKSTATION/scripts/privkeygen.py && rm -fv $FILE && nano $FILE && chmod 555 $FILE
# MNEMONIC=$(hd-wallet-derive --gen-words=24 --gen-key --format=jsonpretty -g | jq '.[0].mnemonic')
# python3 $FILE "$MNEMONIC"

from ecpy.curves import Curve,Point

import sys
import hmac
import hashlib
import binascii
import unicodedata
import base64
import json

TMKMS_KEY_IMPORT_VERSION="v0.0.1.0"

TRACE=False
def trace(x):
    if (TRACE):
        print(x)

def _crypto_scalarmult_curve25519_base(k):
        cv25519 = Curve.get_curve("Ed25519")
        k = int.from_bytes(k, 'little')
        P = k*cv25519.generator
        return cv25519.encode_point(P)

ed25519_n = 2**252 + 27742317777372353535851937790883648493

def _NFKDbytes(str):
    return  unicodedata.normalize('NFKD', str).encode()

def _h512(m):
    return hashlib.sha512(m).digest()

def _h256(m):
    return hashlib.sha256(m).digest()

def _Fk(message, secret):
    return hmac.new(secret, message, hashlib.sha512).digest()

def _Fk256(message, secret):
    return hmac.new(secret, message, hashlib.sha256).digest()

def _get_bit(character, pattern):
    return character & pattern

def _set_bit(character, pattern):
    return character | pattern

def _clear_bit(character, pattern):
    return character & ~pattern

class BIP32Ed25519:

    def __init__(self):
        pass

    def root_key_slip10(self, master_secret):
        trace("ENTER root_key_slip10")
        key=b'ed25519 seed'
        # root chain code
        c = bytearray(_Fk256(b'\x01'+master_secret, key))
        #KL:KR
        I = bytearray(_Fk(master_secret, key))
        kL, kR = I[:32], I[32:]
        while  _get_bit(kL[31], 0b00100000) != 0:
            master_secret = I
            I = bytearray(_Fk(master_secret, key))
            kL, kR = I[:32], I[32:]
        # the lowest 3 bits of the first byte of kL of are cleared
        kL[0]  = _clear_bit( kL[0], 0b00000111)
        # the highest bit of the last byte is cleared
        kL[31] = _clear_bit(kL[31], 0b10000000)
        # the second highest bit of the last byte is set
        kL[31] =   _set_bit(kL[31], 0b01000000)

        # root public key
        A = _crypto_scalarmult_curve25519_base(bytes(kL))
        
        trace("root key: ")
        trace("kL %s"%binascii.hexlify(kL))
        trace("kR %s"%binascii.hexlify(kR))
        trace("A  %s"%binascii.hexlify(A))
        trace("c  %s"%binascii.hexlify(c))
        trace("LEAVE root_key_slip10")
        return ((kL, kR), A, c)

    def private_child_key(self, node, i):
        trace("ENTER private_child_key")
        if not node:
            return None
        # unpack argument
        ((kLP, kRP), AP, cP) = node
        assert 0 <= i < 2**32

        i_bytes = i.to_bytes(4, 'little')
        trace("private_child_key/kLP     : %s"%binascii.hexlify(kLP))
        trace("private_child_key/kRP     : %s"%binascii.hexlify(kRP))
        trace("private_child_key/AP      : %s"%binascii.hexlify(AP))
        trace("private_child_key/cP      : %s"%binascii.hexlify(cP))
        trace("private_child_key/i       : %.04x"%i)

        #compute Z,c
        if i < 2**31:
            # regular child
            trace("regular Z input           : %s"%binascii.hexlify(b'\x02' + AP + i_bytes))
            Z = _Fk(b'\x02' + AP + i_bytes, cP)
            trace("regular c input           : %s"%binascii.hexlify(b'\x03' + AP + i_bytes))
            c = _Fk(b'\x03' + AP + i_bytes, cP)[32:]
        else:
            # harderned child
            trace("harderned Z input     : %s"%binascii.hexlify(b'\x00' + (kLP + kRP) + i_bytes))
            Z = _Fk(b'\x00' + (kLP + kRP) + i_bytes, cP)
            trace("harderned c input     : %s"%binascii.hexlify(b'\x01' + (kLP + kRP) + i_bytes))
            c = _Fk(b'\x01' + (kLP + kRP) + i_bytes, cP)[32:]
        trace("private_child_key/Z       : %s"%binascii.hexlify(Z))
        trace("private_child_key/c       : %s"%binascii.hexlify(c))

        ZL, ZR = Z[:28], Z[32:]
        trace("private_child_key/ZL      : %s"%binascii.hexlify(ZL))
        trace("private_child_key/ZR      : %s"%binascii.hexlify(ZR))

        #compute KLi
        trace("private_child_key/ZLint   : %x"%int.from_bytes(ZL, 'little'))
        trace("private_child_key/kLPint  : %x"%int.from_bytes(kLP, 'little'))
        kLn = int.from_bytes(ZL, 'little') * 8 + int.from_bytes(kLP, 'little')
        trace("private_child_key/kLn     : %x"%kLn)
        
        if kLn % ed25519_n == 0:
            return None

        #compute KRi
        trace("private_child_key/ZRint   : %x"%int.from_bytes(ZR, 'little'))
        trace("private_child_key/kRPint  : %x"%int.from_bytes(kRP, 'little'))
        kRn = (
            int.from_bytes(ZR, 'little') + int.from_bytes(kRP, 'little')
        ) % 2**256
        trace("private_child_key/kRn     : %x"%kRn)

        kL = kLn.to_bytes(32, 'little')
        kR = kRn.to_bytes(32, 'little')
        trace("private_child_key/kL      : %s"%binascii.hexlify(kL))
        trace("private_child_key/kR      : %s"%binascii.hexlify(kR))

        #compue Ai
        A =_crypto_scalarmult_curve25519_base(kL)
        trace("private_child_key/A       : %s"%binascii.hexlify(A))

        trace("LEAVE private_child_key")
        return ((kL, kR), A, c)


    def mnemonic_to_seed(self, mnemonic, passphrase='', prefix=u'mnemonic'):  
        seed = hashlib.pbkdf2_hmac('sha512', _NFKDbytes(mnemonic), _NFKDbytes(prefix+passphrase), 2048)
        return seed

    def derive_seed(self, path, seed):
        root = self.root_key_slip10(seed)
        node = root
        for i in path:
            node = self.private_child_key(node, i)
            ((kLP, kRP), AP, cP) = node
            trace("Node %d"%i)
            trace("  kLP:%s" % binascii.hexlify(kLP))
            trace("  kRP:%s" % binascii.hexlify(kRP))
            trace("   AP:%s" % binascii.hexlify(AP))
            trace("   cP:%s" % binascii.hexlify(cP))
        return node

    def derive_mnemonic(self, path, mnemonic, passphrase='', prefix=u'mnemonic'):
        seed = self.mnemonic_to_seed(mnemonic, passphrase, prefix)
        return self.derive_seed(path, seed)

if __name__ == "__main__":
    arg1=sys.argv[1]
    if arg1 == "version":
        print(TMKMS_KEY_IMPORT_VERSION, end = '')
    elif arg1 == "--help":
        print("tmkms-key-import <mnemonic> <priv_validator_key.json-output> <signing.key-output> <node_key.json-output> <node_id.key-output>")
    else:
        mnem = arg1
        priv_json_path = sys.argv[2]
        priv_key_path = sys.argv[3]
        node_key_path = sys.argv[4]
        node_id_path = sys.argv[5]
        
        path_arr = [ 
            0x80000000 | 44, 
            0x80000000 | 118, 
            0x80000000 | 0,
            0,
            0]

        # Private validator key generator
        priv = BIP32Ed25519().derive_mnemonic(path_arr, mnem)
        ((kL, kR), A, c) = priv

        priv_key = str(base64.b64encode(kL + kR), "utf-8")
        pub_key = str(base64.b64encode(kR), "utf-8")
        address = _h256(kR)[:20].hex()

        priv_validator_key = {
            "address": address.upper(),
            "pub_key": {
                "type": "tendermint/PubKeyEd25519",
                "value": pub_key
            },
            "priv_key": {
                "type": "tendermint/PrivKeyEd25519",
                "value": priv_key
            }
        }

        with open(priv_json_path, 'w') as f:
            json.dump(priv_validator_key, f, ensure_ascii=False, indent=2)
            f.close()

        # base64.b64encode(kL) is the 32B key that can be placed raw inside the key file without need for tmkms import
        with open(priv_key_path, 'w') as f:
            f.write(str(base64.b64encode(kL), "utf-8"))
            f.close()

        node_key = {
            "priv_key": {
                "type": "tendermint/PrivKeyEd25519",
                "value": priv_key
            }
        }

        with open(node_key_path, 'w') as f:
            json.dump(node_key, f, ensure_ascii=False, indent=2)
            f.close()

        with open(node_id_path, 'w') as f:
            f.write(address)
            f.close()
