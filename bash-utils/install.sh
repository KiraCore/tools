#!/bin/bash
ETC_PROFILE="/etc/profile"
set +e && chmod 555 $ETC_PROFILE && source $ETC_PROFILE &>/dev/null && set -e

KIRA_TOOLS_BRANCH="${1,,}"
KIRA_GLOBS_DIR=$2

[ -z "$KIRA_TOOLS_BRANCH" ] && KIRA_TOOLS_BRANCH="master"
[ -z "$KIRA_GLOBS_DIR" ] && KIRA_GLOBS_DIR="/var/kiraglob"
[ -z "$KIRA_TOOLS_SRC" ] && KIRA_TOOLS_SRC="/usr/local/bin/kira-utils.sh"

echo "INFO: Installing KIRA utils... "
echo "INFO: Default tools branch: $TOOLS_BRANCH"
echo "INFO:   Default glob store: $KIRA_GLOBS_DIR"
echo "INFO:    Default utils src: $KIRA_TOOLS_SRC"
sleep 0.5

mkdir -p $KIRA_GLOBS_DIR

cd /tmp
rm -fvr ./tools
rm -fv $KIRA_TOOLS_SRC

git clone https://github.com/KiraCore/tools.git -b $KIRA_TOOLS_BRANCH
cd ./tools/bash-utils

mv -fv ./utils.sh $KIRA_TOOLS_SRC

. $KIRA_TOOLS_SRC

setGlobEnv KIRA_GLOBS_DIR "$KIRA_GLOBS_DIR"
setGlobEnv KIRA_TOOLS_BRANCH "$KIRA_TOOLS_BRANCH"
setGlobEnv KIRA_UTILS_SRC "$KIRA_UTILS_SRC"

 AUTOLOAD_SET=$(getLastLineByPrefix "source $KIRA_TOOLS_SRC" /etc/profile)

 if [ $AUTOLOAD_SET -lt 0 ] ; then
    echo "source $KIRA_TOOLS_SRC || echo \"ERROR: Faile to load kira utils from $KIRA_TOOLS_SRC\"" /etc/profile
 fi

loadGlobEnvs

echoInfo "INFO: SUCCESS!, Installed kira bash-utils $(utilsVersion)"