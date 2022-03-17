#!/usr/bin/env bash
set -e
set -x
. /etc/profile
. ./bash-utils/utils.sh

echoInfo "INFO: KIRA utils, latest version $(utilsVersion)"

[ -z "$SOURCE_BRANCH" ] && BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD || echo "") || BRANCH=$SOURCE_BRANCH

# check if banch is a version branch 
# TODO: add isVersion func to utils
if  ($(isVersion "$BRANCH")) ; then
    echoInfo "INFO: Branch '$BRANCH' is versioned, release file be updated..."
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
else
    echoWarn "WARNING: Branch '$BRANCH' is not versioned, release file will NOT be updated"
fi

# Build `tmconnect`
cd ./tmconnect
make build