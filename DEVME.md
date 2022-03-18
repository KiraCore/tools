# tools
KIRA Tools

## Dependencies

```
UTILS_VER=$(utilsVersion 2> /dev/null || echo "")

# Installing utils is essential to simplify the setup steps
if [[ $(versionToNumber "$UTILS_VER" || echo "0") -lt $(versionToNumber "v0.0.15" || echo "1") ]] ; then
    echo "INFO: KIRA utils were NOT installed on the system, setting up..." && sleep 2
    KIRA_UTILS_BRANCH="v0.0.3" && cd /tmp && rm -fv ./i.sh && \
    wget https://raw.githubusercontent.com/KiraCore/tools/$KIRA_UTILS_BRANCH/bash-utils/install.sh -O ./i.sh && \
    chmod 777 ./i.sh && ./i.sh "$KIRA_UTILS_BRANCH" "/var/kiraglob" && . /etc/profile && loadGlobEnvs
else
    echoInfo "INFO: KIRA utils are up to date, latest version $UTILS_VER"
fi
```

## Build

```
# set env variable to your local repos (will vary depending on the user)
setGlobEnv TOOLS_REPO "/mnt/c/Users/asmodat/Desktop/KIRA/GITHUB/tools"

cd $TOOLS_REPO

make build
```