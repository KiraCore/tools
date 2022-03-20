# tools
KIRA Tools

## Dependencies

```
VERSION="v0.0.8.0" && cd /tmp && rm -fv ./utils.sh && \
CHECKSUM="1cfb806eec03956319668b0a4f02f2fcc956ed9800070cda1870decfe2e6206e" && \
wget https://github.com/KiraCore/tools/releases/download/$VERSION/kira-utils.sh -O ./utils.sh && \
    FILE_HASH=$(sha256sum ./utils.sh | awk '{ print $1 }' | xargs || echo -n "") && \
    [ "$FILE_HASH" == "$CHECKSUM" ] && chmod -v 555 ./utils.sh && \
    ./utils.sh utilsSetup ./utils.sh "/var/kiraglob" && . /etc/profile && \
    utils loadGlobEnvs && utils echoInfo "SUCCESS: kira-utils $(utils utilsVersion) were installed!" || \
    echo "ERROR: Invalid checksum '$FILE_HASH' or utilsSetup failed"
```

## Build

```
# set env variable to your local repos (will vary depending on the user)
setGlobEnv TOOLS_REPO "/mnt/c/Users/asmodat/Desktop/KIRA/GITHUB/tools"

cd $TOOLS_REPO

make build
```