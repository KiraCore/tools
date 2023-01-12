# tools
KIRA Network - useful tools & scripts

## Signatures

All files in KIRA repositories are always signed with [cosign](https://github.com/sigstore/cosign/releases)

Cosign requires simple initial setup of the signer keys described more precisely [here](https://dev.to/n3wt0n/sign-your-container-images-with-cosign-github-actions-and-github-container-registry-3mni)

```bash
# install cosign
COSIGN_VERSION="v1.13.1" && \
if [[ "$(uname -m)" == *"ar"* ]] ; then ARCH="arm64"; else ARCH="amd64" ; fi && echo $ARCH && \
PLATFORM=$(uname) && FILE=$(echo "cosign-${PLATFORM}-${ARCH}" | tr '[:upper:]' '[:lower:]') && \
 wget https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/$FILE && chmod +x -v ./$FILE && \
 mv -fv ./$FILE /usr/local/bin/cosign && cosign version

# save KIRA public cosign key
cat > ./cosign.pub << EOL
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE/IrzBQYeMwvKa44/DF/HB7XDpnE+
f+mU9F/Qbfq25bBWV2+NlYMJv3KvKHNtu3Jknt6yizZjUV4b8WGfKBzFYw==
-----END PUBLIC KEY-----
EOL

# download desired files and the corresponding .sig file from: https://github.com/KiraCore/tools/releases

# verify signature of downloaded files
cosign verify-blob --key=./cosign.pub --signature=./<file>.sig ./<file>
```

## bash-utils

KIRA bash-utils is a general purpose tool for simplifying scripts & commands

```bash
# one line install
TOOLS_VERSION="v0.3.0" && mkdir -p /usr/keys && FILE_NAME="bash-utils.sh" && \
 if [ -z "$KIRA_COSIGN_PUB" ] ; then KIRA_COSIGN_PUB=/usr/keys/kira-cosign.pub ; fi && \
 echo -e "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE/IrzBQYeMwvKa44/DF/HB7XDpnE+\nf+mU9F/Qbfq25bBWV2+NlYMJv3KvKHNtu3Jknt6yizZjUV4b8WGfKBzFYw==\n-----END PUBLIC KEY-----" > $KIRA_COSIGN_PUB && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}" -O ./$FILE_NAME && \
 wget "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/${FILE_NAME}.sig" -O ./${FILE_NAME}.sig && \
 cosign verify-blob --key="$KIRA_COSIGN_PUB" --signature=./${FILE_NAME}.sig ./$FILE_NAME && \
 chmod -v 555 ./$FILE_NAME && ./$FILE_NAME bashUtilsSetup "/var/kiraglob" && . /etc/profile && \
 echoInfo "Installed bash-utils $(bashUtilsVersion)"
```
