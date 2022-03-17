#!/usr/bin/env bash
set -e
set -x
. /etc/profile

UTILS_VER=$(utilsVersion 2> /dev/null || echo "")

# Installing utils is essential to simplify the setup steps
if [[ $(versionToNumber "$UTILS_VER" || echo "0") -lt $(versionToNumber "v0.0.15" || echo "1") ]] ; then
    echo "INFO: KIRA utils were NOT installed on the system, setting up..." && sleep 2
    KIRA_UTILS_BRANCH="v0.0.3" && cd /tmp && rm -fv ./i.sh && \
    wget https://raw.githubusercontent.com/KiraCore/tools/$KIRA_UTILS_BRANCH/bash-utils/install.sh -O ./i.sh && \
    chmod 777 ./i.sh && ./i.sh "$KIRA_UTILS_BRANCH" "/var/kiraglob" && . /etc/profile && loadGlobEnvs
else
    echoInfo "INFO: KIRA utils are up to date, latest version $UTILS_VER" && sleep 2
fi

BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD || echo "")
( [ -z "$BRANCH" ] || [ "${BRANCH,,}" == "head" ] ) && BRANCH="${SOURCE_BRANCH}"

# check if banch is a version branch 
# TODO: add isVersion func to utils
if [[ $(versionToNumber "$BRANCH" || echo "0") -gt 0 ]] ; then
    VERSION=$BRANCH
    RELEASE_FILE=./RELEASE.md
    RELEASE_VERSION=$(grep -Fn -m 1 'Release: ' $RELEASE_FILE | rev | cut -d ":" -f1 | rev | xargs | tr -dc '[:alnum:]\-\.' || echo '')
    RELEASE_LINE_NR=$(getFirstLineByPrefix "Release:" $RELEASE_FILE)

    # If release file is not present or release version is NOT defined then create RELEASE.md or append the Release version
    if ($(isNullOrEmpty "$RELEASE_VERSION")) || [ ! -f $RELEASE_FILE ] || [ $RELEASE_LINE_NR -le 0 ] ; then
        touch $RELEASE_FILE
        echo -e "\n\rRelease: \`$VERSION\`" >> $RELEASE_FILE
    # Otherwsie replace release with the number defined by the constants file
    else
        RELEASE_LINE_NR=$(getFirstLineByPrefix "Release:" $RELEASE_FILE)
        setLineByNumber $RELEASE_LINE_NR "Release: \`$VERSION\`" $RELEASE_FILE
    fi
fi

# Build `tmconnect`
cd ./tmconnect
make build