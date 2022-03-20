# tools
KIRA Tools

## Dependencies

```
VERSION="v0.0.7.0" && cd /tmp && rm -fv ./utils.sh && \
CHECKSUM="5f47b6f6e302b9c582c68894b1dfb231ec81c593ca7bc0d21471f440aca1d9ac" && \
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