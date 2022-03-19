# tools
KIRA Tools

## Dependencies

```
VERSION="v0.0.6.0" && cd /tmp && rm -fv ./kira-utils.sh && \
CHECKSUM="7bdf4da2165fa1828f399622594af68e83e764ba1ddeb472094d882d85dcdd71" && \
wget https://github.com/KiraCore/tools/releases/download/$VERSION/kira-utils.sh && \
    FILE_HASH=$(sha256sum $1 | awk '{ print $1 }' | xargs || echo -n "") && \
    [ "$FILE_HASH" == "$CHECKSUM" ] && . ./utils.sh utilsSetup "/usr/local/bin" "/var/kiraglob" && \
    loadGlobEnvs && echoInfo "SUCCESS: kira-utils $(utilsVersion) were installed!" || \
    echo "ERROR: Invalid checksum '$FILE_HASH' or utilsSetup failed"
```

## Build

```
# set env variable to your local repos (will vary depending on the user)
setGlobEnv TOOLS_REPO "/mnt/c/Users/asmodat/Desktop/KIRA/GITHUB/tools"

cd $TOOLS_REPO

make build
```