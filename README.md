# tools
KIRA Network - useful tools & scripts


## Signatures

All files in KIRA repositories are always signed with [cosign](https://github.com/sigstore/cosign/releases)

Cosign requires simple initial setup of the signer keys described more precisely [here](https://dev.to/n3wt0n/sign-your-container-images-with-cosign-github-actions-and-github-container-registry-3mni)

```bash
# install cosign
if [[ "$(uname -m)" == *"ar"* ]] ; then ARCH="arm64"; else ARCH="amd64" ; fi && echo $ARCH && \
PLATFORM=$(uname) && FILE=$(echo "cosign-${PLATFORM}-${ARCH}" | tr '[:upper:]' '[:lower:]') && \
 wget https://github.com/sigstore/cosign/releases/download/v1.7.2/$FILE && chmod +x -v ./$FILE && \
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
