#!/usr/bin/env bash
# QUICK EDIT: FILE="/usr/local/bin/bash-utils.sh" && rm $FILE && nano $FILE && chmod 555 $FILE
# NOTE: For this script to work properly the KIRA_GLOBS_DIR env variable should be set to "/var/kiraglob" or equivalent & the directory should exist
REGEX_DNS="^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}$"
REGEX_IP="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
REGEX_NODE_ID="^[a-f0-9]{40}$"
REGEX_TXHASH="^[a-fA-F0-9]{64}$"
REGEX_INTEGER="^-?[0-9]+$"
REGEX_NUMBER="^[+-]?([0-9]*[.])?([0-9]+)?$"
REGEX_PUBLIC_IP='^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(?<!172\.(16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31))(?<!127)(?<!^10)(?<!^0)\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(?<!192\.168)(?<!172\.(16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31))\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(?<!\.255$)(?<!\b255.255.255.0\b)(?<!\b255.255.255.242\b)$'
REGEX_KIRA="^(kira)[a-zA-Z0-9]{39}$"
REGEX_VERSION="^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-?)([a-zA-Z]+)?(\.?([0-9]+)?)$"


function bashUtilsVersion() {
    bashUtilsSetup "version" 2> /dev/null || bash-utils bashUtilsSetup "version"
}

# this is default installation script for utils
# ./bash-utils.sh bashUtilsSetup "/var/kiraglob"
function bashUtilsSetup() {
    local BASH_UTILS_VERSION="v0.1.2.3"
    if [ "$1" == "version" ] ; then
        echo "$BASH_UTILS_VERSION"
        return 0
    else
        local GLOBS_DIR="$1"

        local UTILS_SOURCE=$(realpath "$0")
        local VERSION=$($UTILS_SOURCE bashUtilsVersion || echo '')
        local UTILS_DESTINATION="/usr/local/bin/bash-utils.sh"

        if [ -z "$GLOBS_DIR" ] ; then
            [ -z "$KIRA_GLOBS_DIR" ] && KIRA_GLOBS_DIR="/var/kiraglob"
        else
            KIRA_GLOBS_DIR=$GLOBS_DIR
        fi

        if [ "$VERSION" != "$BASH_UTILS_VERSION" ] ; then
            bash-utils echoErr "ERROR: Self check version mismatch, expected '$BASH_UTILS_VERSION', but got '$VERSION'"
            return 1
        elif [ "$UTILS_SOURCE" == "$UTILS_DESTINATION" ] ; then
            bash-utils echoErr "ERROR: Installation source script and destination can't be the same"
            return 1
        elif [ ! -f $UTILS_SOURCE ] ; then
            bash-utils echoErr "ERROR: utils source was NOT found"
            return 1
        else
            mkdir -p "/usr/local/bin"
            cp -fv "$UTILS_SOURCE" "$UTILS_DESTINATION"
            cp -fv "$UTILS_SOURCE" "/usr/local/bin/bash-utils"
            chmod -v 555 $UTILS_DESTINATION "/usr/local/bin/bash-utils"

            local SUDOUSER="${SUDO_USER}" && [ "$SUDOUSER" == "root" ] && SUDOUSER=""
            local USERNAME="${USER}" && [ "$USERNAME" == "root" ] && USERNAME=""
            local LOGNAME=$(logname 2> /dev/null echo "") && [ "$LOGNAME" == "root" ] && LOGNAME=""

            local TARGET="/$LOGNAME/.bashrc" && [ -f $TARGET ] && chmod 777 $TARGET && echoInfo "INFO: /etc/profile executable target set to $TARGET"
            TARGET="/$USERNAME/.bashrc" && [ -f $TARGET ] && chmod 777 $TARGET && echoInfo "INFO: /etc/profile executable target set to $TARGET"
            TARGET="/$SUDOUSER/.bashrc" && [ -f $TARGET ] && chmod 777 $TARGET && echoInfo "INFO: /etc/profile executable target set to $TARGET"
            TARGET="/root/.bashrc" && [ -f $TARGET ] && chmod 777 $TARGET && echoInfo "INFO: /etc/profile executable target set to $TARGET"
            TARGET=~/.bashrc && [ -f $TARGET ] && chmod 777 $TARGET && echoInfo "INFO: /etc/profile executable target set to $TARGET"
            TARGET=~/.zshrc && [ -f $TARGET ] && chmod 777 $TARGET && echoInfo "INFO: /etc/profile executable target set to $TARGET"
            TARGET=~/.profile && [ -f $TARGET ] && chmod 777 $TARGET && echoInfo "INFO: /etc/profile executable target set to $TARGET"

            mkdir -p $KIRA_GLOBS_DIR

            bash-utils setGlobEnv KIRA_GLOBS_DIR "$KIRA_GLOBS_DIR"
            bash-utils setGlobEnv KIRA_TOOLS_SRC "$UTILS_DESTINATION"

            local AUTOLOAD_SET=$(bash-utils getLastLineByPrefix "source $UTILS_DESTINATION" /etc/profile 2> /dev/null || echo "-1")

            if [[ $AUTOLOAD_SET -lt 0 ]] ; then
                echo "source $UTILS_DESTINATION || echo \"ERROR: Failed to load kira bash-utils from '$UTILS_DESTINATION'\"" >> /etc/profile
            fi

            bash-utils loadGlobEnvs

            echoInfo "INFO: SUCCESS!, Installed kira bash-utils $(bashUtilsVersion)"
        fi
    fi
}

# bash 3 (MAC) compatybility
# "$(toLower "$1")"
function toLower() {
    echo $(echo "$1" |  tr '[:upper:]' '[:lower:]' )
}

# bash 3 (MAC) compatybility
# "$(toUpper "$1")"
function toUpper() {
    echo $(echo "$1" |  tr '[:lower:]' '[:upper:]' )
}

function isNullOrEmpty() {
    local val=$(toLower "$1")
    if [ -z "$val" ] || [ "$val" == "null" ] || [ "$val" == "nil" ] ; then echo "true" ; else echo "false" ; fi
}

function delWhitespaces() {
    echo "$1" | tr -d '\011\012\013\014\015\040'
}

function isNullOrWhitespaces() {
    isNullOrEmpty $(delWhitespaces "$1")
}

function isKiraAddress() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_KIRA ]] && echo "true" || echo "false" ; fi
}

function isTxHash() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_TXHASH ]] && echo "true" || echo "false" ; fi
}

function isDns() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_DNS ]] && echo "true" || echo "false" ; fi
}

function isIp() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_IP ]] && echo "true" || echo "false" ; fi
}

function isPublicIp() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [ "$(echo "$1" | grep -P $REGEX_PUBLIC_IP | xargs || echo \"\")" == "$1" ] && echo "true" || echo "false" ; fi
}

function isDnsOrIp() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else
        kg_var="false" && ($(isDns "$1")) && kg_var="true"
        [ "$kg_var" != "true" ] && ($(isIp "$1")) && kg_var="true"
        echo $kg_var
    fi
}

function isInteger() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ $1 =~ $REGEX_INTEGER ]] && echo "true" || echo "false" ; fi
}

function isBoolean() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else
        local val=$(toLower "$1")
        if [ "$val" == "false" ] || [ "$val" == "true" ] ; then echo "true"
        else echo "false" ; fi
    fi
}

function isNodeId() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_NODE_ID ]] && echo "true" || echo "false" ; fi
}

function isNumber() {
     if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_NUMBER ]] && echo "true" || echo "false" ; fi
}

function isNaturalNumber() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else ( ($(isInteger "$1")) && [[ $1 -ge 0 ]] ) && echo "true" || echo "false" ; fi
}

function isLetters() {
    [[ "$1" =~ [^a-zA-Z] ]] && echo "false" || echo "true"
}

function isAlphanumeric() {
    [[ "$1" =~ [^a-zA-Z0-9] ]] && echo "false" || echo "true"
}

function isPort() {
    ( ($(isNaturalNumber $1)) && (($1 > 0)) && (($1 < 65536)) ) && echo "true" || echo "false"
}

function isMnemonic() {
    kg_mnem=$(echo "$1" | xargs 2> /dev/null || echo -n "")
    kg_count=$(echo "$kg_mnem" | wc -w 2> /dev/null || echo -n "")
    (! $(isNaturalNumber $kg_count)) && kg_count=0
    if (( $kg_count % 3 == 0 )) && [[ $kg_count -ge 12 ]] ; then echo "true" ; else echo "false" ; fi
}

function isVersion {
  [[ "$1" =~ $REGEX_VERSION ]] && echo "true" || echo "false"
}

function date2unix() {
    kg_date_tmp="$*" && kg_date_tmp=$(echo "$kg_date_tmp" | xargs 2> /dev/null || echo -n "")
    if (! $(isNullOrWhitespaces "$kg_date_tmp")) && (! $(isNaturalNumber $kg_date_tmp)) ; then
        kg_date_tmp=$(date -d "$kg_date_tmp" +"%s" 2> /dev/null || echo "0")
    fi

    ($(isNaturalNumber "$kg_date_tmp")) && echo "$kg_date_tmp" || echo "0"
}

function isPortOpen() {
    kg_addr=$1 && kg_port=$2 && kg_timeout=$3
    (! $(isNaturalNumber $kg_timeout)) && kg_timeout=1
    if (! $(isDnsOrIp $kg_addr)) || (! $(isPort $kg_port)) ; then echo "false"
    elif timeout $kg_timeout nc -z $kg_addr $kg_port ; then echo "true"
    else echo "false" ; fi
}

function fileSize() {
    local BYTES=$(stat -c%s $1 2> /dev/null || echo -n "")
    ($(isNaturalNumber "$BYTES")) && echo "$BYTES" || echo -n "0"
}

function isFileEmpty() {
    local FILE="$1"
    if [ -z "$FILE" ] || [ ! -f "$FILE" ] || [ ! -s "$FILE" ] ; then echo "true" ; else
        local TEXT=$(head -c 64 "$FILE" 2>/dev/null | tr -d '\0\011\012\013\014\015\040' 2>/dev/null || echo '')
        [ -z "$TEXT" ] && TEXT=$(tail -c 64 "$FILE" 2>/dev/null | tr -d '\0\011\012\013\014\015\040' 2>/dev/null || echo '')
        [ -z "$TEXT" ] && TEXT=$(cat $FILE | tr -d '\0\011\012\013\014\015\040' 2>/dev/null || echo -n "")
        [ ! -z "$TEXT" ] && echo "false" || echo "true"
    fi
}

# Example use case: [[ $(versionToNumber "v0.0.0.3") -lt $(versionToNumber "v1.0.0.2") ]] && echo true || echo false
function versionToNumber() {
    local version=$(echo "$1" | grep -o '[^-]*$' 2> /dev/null || echo "v0.0.0.0")
    local major=$(echo $version | cut -d. -f1 | sed 's/[^0-9]*//g' 2> /dev/null || echo "0") && (! $(isNaturalNumber "$major")) && major=0
    local minor=$(echo $version | cut -d. -f2 | sed 's/[^0-9]*//g' 2> /dev/null || echo "0") && (! $(isNaturalNumber "$minor")) && minor=0
    local micro=$(echo $version | cut -d. -f3 | sed 's/[^0-9]*//g' 2> /dev/null || echo "0") && (! $(isNaturalNumber "$micro")) && micro=0
    local build=$(echo $version | cut -d. -f4 | sed 's/[^0-9]*//g' 2> /dev/null || echo "0") && (! $(isNaturalNumber "$build")) && build=0
    local sum=0
    sum=$(( sum + ( 1 * build ) )) && [[ $build -le 0 ]] && build=0
    sum=$(( sum + ( 10000 * micro  ) )) && [[ $micro -le 0 ]] && micro=10000
    sum=$(( sum + ( 100000000 * minor ) )) && [[ $minor -le 0 ]] && minor=100000000
    sum=$(( sum + ( 1000000000000 * major) )) && [[ $major -le 0 ]] && major=1000000000000
    echo $sum
}

function sha256() {
    if [ -z "$1" ] ; then
        echo $(cat | sha256sum | awk '{ print $1 }' | xargs || echo -n "") || echo -n ""
    else
        [ -f $1 ] && echo $(sha256sum $1 | awk '{ print $1 }' | xargs || echo -n "") || echo -n ""
    fi
}

function md5() {
    if [ -z "$1" ] ; then
        echo $(cat | md5sum | awk '{ print $1 }' | xargs || echo -n "") || echo -n ""
    else
        [ -f $1 ] && echo $(md5sum $1 | awk '{ print $1 }' | xargs || echo -n "") || echo -n ""
    fi
}

function safeWget() {
    local OUT_PATH=$1
    local FILE_URL=$2
    local EXPECTED_HASH=$3
    local OUT_NAME=$(basename $OUT_PATH)
    local TMP_DIR=/tmp/downloads
    local TMP_PATH="$TMP_DIR/$OUT_NAME"

    mkdir -p $TMP_DIR
    local FILE_HASH=$(sha256 $TMP_PATH)
    
    if [ "$FILE_HASH" == "$EXPECTED_HASH" ] && [ ! -z "$EXPECTED_HASH" ]; then
        echoInfo "INFO: No need to download, file with the hash '$FILE_HASH' was already found in the '$TMP_DIR' directory"
        [ "$TMP_PATH" != "$OUT_PATH" ] && cp -fv $TMP_PATH $OUT_PATH
    else
        rm -fv $OUT_PATH
        wget "$FILE_URL" -O $TMP_PATH
        [ "$TMP_PATH" != "$OUT_PATH" ] && cp -fv $TMP_PATH $OUT_PATH
        FILE_HASH=$(sha256 $OUT_PATH)
    fi

    if ($(isFileEmpty $OUT_PATH)) ; then
        echoErr "ERROR: Failed download from '$FILE_URL', file is exmpty or was NOT found!"
        return 1
    elif [ "$FILE_HASH" != "$EXPECTED_HASH" ]; then
        rm -fv $OUT_PATH || echoErr "ERROR: Failed to delete '$OUT_PATH'"
        echoErr "ERROR: Safe download filed: '$FILE_URL' -x-> '$OUT_PATH'"
        echoErr "ERROR: Expected hash: '$EXPECTED_HASH', but got '$FILE_HASH'"
        return 1
    else
        echoInfo "INFO: Safe download suceeded: '$FILE_URL' ---> '$(realpath $OUT_PATH)'"
    fi
}

function getCpuCores() {
    local CORES=$(cat /proc/cpuinfo | grep processor | wc -l 2> /dev/null || echo "0")
    ($(isNaturalNumber "$CORES")) && echo $CORES || echo "0"
}

function getRamTotal() {
    local MEMORY=$(grep MemTotal /proc/meminfo | awk '{print $2}' || echo "0")
    ($(isNaturalNumber "$MEMORY")) && echo $MEMORY || echo "0"
}

function getArch() {
    local ARCH=$(uname -m)
    if [[ "$ARCH" == *"arm"* ]] || [[ "$ARCH" == *"aarch"* ]] ; then
        echo "arm64"
    elif [[ "$ARCH" == *"x64"* ]] || [[ "$ARCH" == *"x86_64"* ]] || [[ "$ARCH" == *"amd64"* ]] || [[ "$ARCH" == *"amd"* ]] ; then
        echo "amd64"
    else
        echo "$ARCH"
    fi
}

function tryMkDir {
    for kg_var in "$@" ; do
        kg_var=$(echo "$kg_var" | tr -d '\011\012\013\014\015\040' 2>/dev/null || echo -n "")
        [ -z "$kg_var" ] && continue
        [ "$(toLower "$kg_var")" == "-v" ] && continue
        
        if [ -f "$kg_var" ] ; then
            if [ "$(toLower "$1")" == "-v" ] ; then
                rm -f "$kg_var" 2> /dev/null || : 
                [ ! -f "$kg_var" ] && echo "removed file '$kg_var'" || echo "failed to remove file '$kg_var'"
            else
                rm -f 2> /dev/null || :
            fi
        fi

        if [ "$(toLower "$1")"== "-v" ]  ; then
            [ ! -d "$kg_var" ] && mkdir -p "$var" 2> /dev/null || :
            [ -d "$kg_var" ] && echo "created directory '$kg_var'" || echo "failed to create direcotry '$kg_var'"
        elif [ ! -d "$kg_var" ] ; then
            mkdir -p "$kg_var" 2> /dev/null || :
        fi
    done
}

function tryCat {
    if ($(isFileEmpty $1)) ; then
        echo -ne "$2"
    else
        cat $1 2>/dev/null || echo -ne "$2"
    fi
}

function isDirEmpty() {
    if [ -z "$1" ] || [ ! -d "$1" ] || [ -z "$(ls -A "$1")" ] ; then echo "true" ; else
        echo "false"
    fi
}

function isSimpleJsonObjOrArr() {
    if ($(isNullOrEmpty "$1")) ; then echo "false"
    else
        kg_HEADS=$(echo "$1" | head -c 8)
        kg_TAILS=$(echo "$1" | tail -c 8)
        kg_STR=$(echo "${kg_HEADS}${kg_TAILS}" | tr -d '\n' | tr -d '\r' | tr -d '\a' | tr -d '\t' | tr -d ' ')
        if ($(isNullOrEmpty "$kg_STR")) ; then echo "false"
        elif [[ "$kg_STR" =~ ^\{.*\}$ ]] ; then echo "true"
        elif [[ "$kg_STR" =~ ^\[.*\]$ ]] ; then echo "true"
        else echo "false"; fi
    fi
}

function isSimpleJsonObjOrArrFile() {
    if [ ! -f "$1" ] ; then echo "false"
    else
        kg_HEADS=$(head -c 8 $1 2>/dev/null || echo -ne "")
        kg_TAILS=$(tail -c 8 $1 2>/dev/null || echo -ne "")
        echo $(isSimpleJsonObjOrArr "${kg_HEADS}${kg_TAILS}")
    fi
}

function jsonParse() {
    local QUERY=""
    local FIN=""
    local FOUT=""
    local INPUT=$(echo $1 | xargs 2> /dev/null 2> /dev/null || echo -n "")
    [ ! -z "$2" ] && FIN=$(realpath $2 2> /dev/null || echo -n "")
    [ ! -z "$3" ] && FOUT=$(realpath $3 2> /dev/null || echo -n "")
    if [ ! -z "$INPUT" ] ; then
        for k in ${INPUT//./ } ; do
            k=$(echo $k | xargs 2> /dev/null || echo -n "") && [ -z "$k" ] && continue
            [[ "$k" =~ ^\[.*\]$ ]] && QUERY="${QUERY}${k}" && continue
            ($(isNaturalNumber "$k")) && QUERY="${QUERY}[$k]" || QUERY="${QUERY}[\"$k\"]" 
        done
    fi
    if [ ! -z "$FIN" ] ; then
        if [ ! -z "$FOUT" ] ; then
            [ "$FIN" != "$FOUT" ] && rm -f "$FOUT" || :
            python3 -c "import json,sys;fin=open('$FIN',\"r\");obj=json.load(fin);fin.close();fout=open('$FOUT',\"w\",encoding=\"utf8\");json.dump(obj$QUERY,fout,separators=(',',':'),ensure_ascii=False);fout.close()"
        else
            python3 -c "import json,sys;f=open('$FIN',\"r\");obj=json.load(f);print(json.dumps(obj$QUERY,separators=(',', ':'),ensure_ascii=False).strip(' \t\n\r\"'));f.close()"
        fi
    else
        cat | python3 -c "import json,sys;obj=json.load(sys.stdin);print(json.dumps(obj$QUERY,separators=(',', ':'),ensure_ascii=False).strip(' \t\n\r\"'));"
    fi
}

function isFileJson() {
    if (! $(isFileEmpty "$1")) ; then
        jsonParse "" "$1" &> /dev/null && echo "true" || echo "false"
    else
        echo "false"
    fi
}

function jsonQuickParse() {
    local OUT=""
    if [ -z "$2" ] ; then
        OUT=$(cat | grep -Eo "\"$1\"[^,]*" 2> /dev/null | grep -Eo '[^:]*$' 2> /dev/null | xargs 2> /dev/null | awk '{print $1;}' 2> /dev/null 2> /dev/null)
    else
        ($(isFileEmpty $2)) && return 2
        OUT=$(grep -Eo "\"$1\"[^,]*" $2 2> /dev/null | grep -Eo '[^:]*$' 2> /dev/null | xargs 2> /dev/null | awk '{print $1;}' 2> /dev/null 2> /dev/null)
    fi
    OUT=${OUT%\}}
    ($(isNullOrEmpty "$OUT")) && return 1
    echo "$OUT"
}

function jsonEdit() {
    local QUERY=""
    local FIN=""
    local FOUT=""
    local INPUT=$(echo $1 | xargs 2> /dev/null 2> /dev/null || echo -n "")
    local VALUE="$2"
    [ ! -z "$3" ] && FIN=$(realpath $3 2> /dev/null || echo -n "")
    [ ! -z "$4" ] && FOUT=$(realpath $4 2> /dev/null || echo -n "")
    [ "$(toLower "$VALUE")" == "null" ] && VALUE="None"
    [ "$(toLower "$VALUE")" == "true" ] && VALUE="True"
    [ "$(toLower "$VALUE")" == "false" ] && VALUE="False"
    if [ ! -z "$INPUT" ] ; then
        for k in ${INPUT//./ } ; do
            k=$(echo $k | xargs 2> /dev/null || echo -n "") && [ -z "$k" ] && continue
            [[ "$k" =~ ^\[.*\]$ ]] && QUERY="${QUERY}${k}" && continue
            ($(isNaturalNumber "$k")) && QUERY="${QUERY}[$k]" || QUERY="${QUERY}[\"$k\"]" 
        done
    fi
    if [ ! -z "$FIN" ] ; then
        if [ ! -z "$FOUT" ] ; then
            [ "$FIN" != "$FOUT" ] && rm -f "$FOUT" || :
            python3 -c "import json,sys;fin=open('$FIN',\"r\");obj=json.load(fin);obj$QUERY=$VALUE;fin.close();fout=open('$FOUT',\"w\",encoding=\"utf8\");json.dump(obj,fout,separators=(',',':'),ensure_ascii=False);fout.close()"
        else
            python3 -c "import json,sys;f=open('$FIN',\"r\");obj=json.load(f);obj$QUERY=$VALUE;print(json.dumps(obj,separators=(',', ':'),ensure_ascii=False).strip(' \t\n\r\"'));f.close()"
        fi
    else
        cat | python3 -c "import json,sys;obj=json.load(sys.stdin);obj$QUERY=$VALUE;print(json.dumps(obj$QUERY,separators=(',', ':'),ensure_ascii=False).strip(' \t\n\r\"'));"
    fi
}

function jsonObjEdit() {
    local QUERY=""
    local FVAL=""
    local FIN=""
    local FOUT=""
    local INPUT=$(echo $1 | xargs 2> /dev/null 2> /dev/null || echo -n "")
    [ ! -z "$2" ] && FVAL=$(realpath $2 2> /dev/null || echo -n "")
    [ ! -z "$3" ] && FIN=$(realpath $3 2> /dev/null || echo -n "")
    [ ! -z "$4" ] && FOUT=$(realpath $4 2> /dev/null || echo -n "")
    [ "$(toLower "$VALUE")" == "null" ] && VALUE="None"
    [ "$(toLower "$VALUE")" == "true" ] && VALUE="True"
    [ "$(toLower "$VALUE")" == "false" ] && VALUE="False"
    if [ ! -z "$INPUT" ] ; then
        for k in ${INPUT//./ } ; do
            k=$(echo $k | xargs 2> /dev/null || echo -n "") && [ -z "$k" ] && continue
            [[ "$k" =~ ^\[.*\]$ ]] && QUERY="${QUERY}${k}" && continue
            ($(isNaturalNumber "$k")) && QUERY="${QUERY}[$k]" || QUERY="${QUERY}[\"$k\"]" 
        done
    fi
    if [ ! -z "$FIN" ] ; then
        if [ ! -z "$FOUT" ] ; then
            [ "$FIN" != "$FOUT" ] && rm -f "$FOUT" || :
            python3 -c "import json,sys;fin=open('$FIN',\"r\");fin2=open('$FVAL',\"r\");obj2=json.load(fin2);obj=json.load(fin);obj$QUERY=obj2;fin.close();fout=open('$FOUT',\"w\",encoding=\"utf8\");json.dump(obj,fout,separators=(',',':'),ensure_ascii=False);fin2.close();fout.close()" || SUCCESS="false"
        else
            python3 -c "import json,sys;f=open('$FIN',\"r\");fin2=open('$FVAL',\"r\");obj2=json.load(fin2);obj=json.load(f);obj$QUERY=obj2;print(json.dumps(obj,separators=(',', ':'),ensure_ascii=False).strip(' \t\n\r\"'));f.close();fin2.close()"
        fi
    else
        cat | python3 -c "import json,sys;obj=json.load(sys.stdin);fin2=open('$FVAL',\"r\");obj2=json.load(fin2);obj$QUERY=obj2;print(json.dumps(obj$QUERY,separators=(',', ':'),ensure_ascii=False).strip(' \t\n\r\"'));fin2.close()"
    fi
}

# e.g. urlExists "18.168.78.192:11000/download/peers.txt"
function urlExists() {
    if ($(isNullOrEmpty "$1")) ; then echo "false"
    elif curl -r0-0 --fail --silent "$1" >/dev/null; then echo "true"
    else echo "false" ; fi
}

# TODO: Investigate 0 output
# urlContentLength 18.168.78.192:11000/api/snapshot
function urlContentLength() {
    local VAL=$(curl --fail $1 --dump-header /dev/fd/1 --silent 2> /dev/null | grep -i Content-Length -m 1 2> /dev/null | awk '{print $2}' 2> /dev/null || echo -n "")
    # remove invisible whitespace characters
    VAL=$(echo ${VAL%$'\r'})
    (! $(isNaturalNumber $VAL)) && VAL=0
    echo $VAL
}

function globName() {
    echo $(echo "$(toLower "$1")" | tr -d '\011\012\013\014\015\040' | md5sum | awk '{ print $1 }')
    return 0
}

function globFile() {
    if [ ! -z "$2" ] && [ -d $2 ] ; then
        echo "${2}/$(globName $1)"
    else
        local TARGET_DIR="$KIRA_GLOBS_DIR" && ($(isNullOrEmpty "$TARGET_DIR")) && TARGET_DIR="/var/kiraglob"
        echo "${TARGET_DIR}/$(globName $1)"
    fi
    return 0
}

function globGet() {
    local FILE=$(globFile "$1" "$2")
    [[ -s "$FILE" ]] && cat $FILE || echo ""
    return 0
}

# threadsafe global get
function globGetTS() {
    local FILE=$(globFile "$1" "$2")
    [ -s "$FILE" ] && sem --id "$1" "cat $FILE" || echo ""
    return 0
}

function globSet() {
    [ ! -z "$3" ] && local FILE=$(globFile "$1" "$3") || local FILE=$(globFile "$1")
    touch "$FILE.tmp"
    [ ! -z ${2+x} ] && echo "$2" > "$FILE.tmp" || cat > "$FILE.tmp"
    mv -f "$FILE.tmp" $FILE
}

# threadsafe global set
function globSetTS() {
    [ ! -z "$3" ] && local FILE=$(globFile "$1" "$3") || local FILE=$(globFile "$1")
    touch "$FILE"
    [ ! -z ${2+x} ] && sem --id "$1" "echo $2 > $FILE" || sem --id "$1" --pipe "cat > $FILE"
}

function globEmpty() {
    ($(isFileEmpty $(globFile "$1" "$2"))) && echo "true" || echo "false"
}

function globDel {
    for DEL_KEY in "$@" ; do
        [ -z "$DEL_KEY" ] && continue
        globSet "$DEL_KEY" ""
    done
}

function timerStart() {
    local NAME=$1 && ($(isNullOrEmpty "$NAME")) && NAME="${BASH_SOURCE}"
    globSet "timer_start_${NAME}" "$(date -u +%s)"
    globSet "timer_stop_${NAME}" ""
    globSet "timer_elapsed_${NAME}" ""
    return 0
}

# if TIMEOUT is set then time left until TIMEOUT is calculated
function timerSpan() {
    local TIME="$(date -u +%s)"
    local NAME=$1 && ($(isNullOrEmpty "$NAME")) && NAME="${BASH_SOURCE}"
    local TIMEOUT=$2
    local START_TIME=$(globGet "timer_start_${NAME}") && (! $(isNaturalNumber "$START_TIME")) && START_TIME="$TIME"
    local END_TIME=$(globGet "timer_stop_${NAME}") && (! $(isNaturalNumber "$END_TIME")) && END_TIME="$TIME"
    local ELAPSED=$(globGet "timer_elapsed_${NAME}") && (! $(isNaturalNumber "$ELAPSED")) && ELAPSED="0"
    local SPAN="$(($END_TIME - $START_TIME))" && [[ $SPAN -lt 0 ]] && SPAN="0"
    SPAN="$(($SPAN + $ELAPSED))" 
    
    if ($(isNaturalNumber $TIMEOUT)) ; then
        local DELTA=$(($TIMEOUT - $SPAN))
        [[ $DELTA -lt 0 ]] && echo "0" || echo "$DELTA"
    else
        echo $SPAN
    fi
    return 0
}

function timerPause() {
    local TIME="$(date -u +%s)"
    local NAME=$1 && ($(isNullOrEmpty "$NAME")) && NAME="${BASH_SOURCE}"
    local END_TIME=$(globGet "timer_stop_${NAME}")

    if (! $(isNaturalNumber "$END_TIME")) ; then
        globSet "timer_stop_${NAME}" "$TIME"
        local OLD_ELAPSED=$(globGet "timer_elapsed_${NAME}") && (! $(isNaturalNumber "$OLD_ELAPSED")) && OLD_ELAPSED="0"
        local START_TIME=$(globGet "timer_start_${NAME}") && (! $(isNaturalNumber "$START_TIME")) && START_TIME="$TIME"
        local END_TIME=$(globGet "timer_stop_${NAME}") && (! $(isNaturalNumber "$END_TIME")) && END_TIME="$TIME"
        local NOW_ELAPSED="$(($END_TIME - $START_TIME))" && [[ $NOW_ELAPSED -lt 0 ]] && NOW_ELAPSED="0"
        globSet "timer_start_${NAME}" "$TIME"
        globSet "timer_elapsed_${NAME}" "$(($NOW_ELAPSED + $OLD_ELAPSED))"
    fi
    return 0
}

function timerUnpause() {
    local NAME=$1 && ($(isNullOrEmpty "$NAME")) && NAME="${BASH_SOURCE}"
    local END_TIME=$(globGet "timer_stop_${NAME}")

    if ($(isNaturalNumber "$END_TIME")) ; then
        globSet "timer_start_${NAME}" "$(date -u +%s)"
        globSet "timer_stop_${NAME}" ""
    fi
    return 0
}

function timerDel() {
    if [ -z "$@" ] ; then
        local NAME="$BASH_SOURCE"
        globSet "timer_start_${NAME}" ""
        globSet "timer_stop_${NAME}" ""
    else
        for CLEAR_KEY in "$@" ; do
            [ -z "$CLEAR_KEY" ] && CLEAR_KEY="$BASH_SOURCE"
            globSet "timer_start_${CLEAR_KEY}" ""
            globSet "timer_stop_${CLEAR_KEY}" ""
        done
    fi
    return 0
}

function prettyTime {
  local T=$(date2unix "$1")
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && (( $D > 1 )) && printf '%d days ' $D
  (( $D > 0 )) && (( $D < 2 )) && printf '%d day ' $D
  (( $H > 0 )) && (( $H > 1 )) && printf '%d hours ' $H
  (( $H > 0 )) && (( $H < 2 )) && printf '%d hour ' $H
  (( $M > 0 )) && (( $M > 1 )) && printf '%d minutes ' $M
  (( $M > 0 )) && (( $M < 2 )) && printf '%d minute ' $M
  (( $S != 1 )) && printf '%d seconds\n' $S || printf '%d second\n' $S
}

function prettyTimeSlim {
  local T=$(date2unix "$1")
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && (( $D > 1 )) && printf '%dd ' $D
  (( $D > 0 )) && (( $D < 2 )) && printf '%dd ' $D
  (( $H > 0 )) && (( $H > 1 )) && printf '%dh ' $H
  (( $H > 0 )) && (( $H < 2 )) && printf '%dh ' $H
  (( $M > 0 )) && (( $M > 1 )) && printf '%dm ' $M
  (( $M > 0 )) && (( $M < 2 )) && printf '%dm ' $M
  (( $S != 1 )) && printf '%ds\n' $S || printf '%ds\n' $S
}

function resolveDNS {
    if ($(isIp "$1")) ; then
        echo "$1"
    else
        local DNS_NAME=$(timeout 10 dig +short "$1" 2> /dev/null || echo -e "")
        ($(isIp $DNS_NAME)) && echo $DNS_NAME || echo -e ""
    fi
}

function isSubStr {
    local STR="$1"
    local SUB="$2"
    SUB=${SUB//"\n"/"\\n"}
    local L1=${#STR}
    STR=${STR//"$SUB"/""}
    local L2=${#STR}
    [ $L1 -ne $L2 ] && echo "true" || echo "false"
}

function isCommand {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; elif command -v "$1" &> /dev/null ; then echo "true" ; else echo "false" ; fi
}

function isServiceActive {
    local ISACT=$(systemctl is-active "$1" 2> /dev/null || echo "inactive")
    [ "$(toLower "$ISACT")" == "active" ] && echo "true" || echo "false"
}

# returns 0 if failure, otherwise natural number in microseconds
function pingTime() {
    if ($(isDnsOrIp "$1")) ; then
        local PAVG=$(ping -qc1 "$1" 2>&1 | awk -F'/' 'END{ print (/^rtt/? $5:"FAIL") }' 2> /dev/null || echo -n "")
        if ($(isNumber $PAVG)) ; then
            local PAVGUS=$(echo "scale=3; ( $PAVG * 1000 )" | bc 2> /dev/null || echo -n "")
            PAVGUS=$(echo "scale=0; ( $PAVGUS / 1 ) " | bc 2> /dev/null || echo -n "")
            ($(isNaturalNumber $PAVGUS)) && echo "$PAVGUS" || echo "0"
        else echo "0" ; fi
    else echo "0" ; fi
}

function pressToContinue {
    if ($(isNullOrEmpty "$1")) ; then
        read -n 1 -s 
        globSet OPTION ""
    else
        while : ; do
            local kg_OPTION=""
            local FOUND=false
            read -n 1 -s kg_OPTION
            kg_OPTION=$(toLower "$kg_OPTION")
            for kg_var in "$@" ; do
                kg_var=$(echo "$kg_var" | tr -d '\011\012\013\014\015\040' 2>/dev/null || echo -n "")
                [ "$(toLower "$kg_var")" == "$kg_OPTION" ] && globSet OPTION "$kg_OPTION" && FOUND=true && break
            done
            [ "$FOUND" == "true" ] && break
        done
    fi
    echo ""
}

displayAlign() {
    local align=$1
    local width=$2
    local text=$3

    if [ $align == "center" ]; then
        local textRight=$(((${#text} + $width) / 2))
        printf "|%*s %*s\n" $textRight "$text" $(($width - $textRight)) "|"
    elif [ $align == "left" ]; then
        local textRight=$width
        printf "|%-*s|\n" $textRight "$text"
    fi
}

function echoInfo() {
    echo -e "\e[0m\e[36;1m${1}\e[0m"
}
function echoWarn() {
    echo -e "\e[0m\e[33;1m${1}\e[0m"
}
function echoErr() {
    echo -e "\e[0m\e[31;1m${1}\e[0m"
}
function echoInf() {
    echoInfo "${1}"
}
function echoWarning() {
    echoWarn "${1}"
}
function echoError() {
    echoErr "${1}"
}

function echoNInfo() {
    echo -en "\e[0m\e[36;1m${1}\e[0m"
}
function echoNWarn() {
    echo -en "\e[0m\e[33;1m${1}\e[0m"
}
function echoNErr() {
    echo -en "\e[0m\e[31;1m${1}\e[0m"
}
function echoNInf() {
    echoNInfo "${1}"
}
function echoNWarning() {
    echoNWarn "${1}"
}
function echoNError() {
    echoNErr "${1}"
}

# echo command with a line number
function echol() {
    grep -n "$1" $0 |  sed "s/echo_line_no//" 
}

# for now this funciton is only intended for env variables discovery
function getNLineByPrefix() {
    local INDEX=$1
    local PREFIX=$2
    local FILE=$3
    INDEX="$((INDEX-1))"
    if ($(isNullOrWhitespaces "$PREFIX")) || ($(isNullOrWhitespaces "$FILE")) || [ ! -f $FILE ] ; then echo "-1" ; else
        PREFIX=${PREFIX//"="/"\="}
        PREFIX=${PREFIX//"/"/"\/"}
        PREFIX=${PREFIX//"["/"\["}
        PREFIX=${PREFIX//"*"/"\*"}
        local lines=$(sed -n "/^[[:blank:]]*${PREFIX}/=" $FILE)
        if ($(isNullOrWhitespaces "$lines")) ; then echo "-1" ; else
            local lineArr=($(echo $lines))
            local lineNr=${lineArr[$INDEX]}
            ($(isNaturalNumber "$lineNr")) && echo "$lineNr" || echo "-1"
        fi
    fi
}

function getLastLineByPrefix() {
    getNLineByPrefix "0" "$1" "$2"
}

function getFirstLineByPrefix() {
    getNLineByPrefix "1" "$1" "$2"
}

function setLineByNumber() {
    local INDEX=$1
    local TEXT=$2
    local FILE=$3
    [ ! -f "$FILE" ] && echoErr "ERROR: File '$FILE' does NOT exist, nothing can be set!"
    sed -i"" "$INDEX c\
$TEXT" $FILE
}

function setNLineByPrefix() {
    local INDEX=$1
    local PREFIX=$2
    local TEXT=$3
    local FILE=$4
    local LINE=$(getNLineByPrefix "$INDEX" "$PREFIX" "$FILE")
    if [[ $LINE -ge 0 ]] ; then
        setLineByNumber "$LINE" "$TEXT" "$FILE"
        echo "true"
    else
        echo "false"
    fi
}

function setLastLineByPrefix() {
    setNLineByPrefix "0" "$1" "$2" "$3"
}

function setFirstLineByPrefix() {
    setNLineByPrefix "1" "$1" "$2" "$3"
}

function setLastLineByPrefixOrAppend() {
    local PREFIX=$1
    local TEXT=$2
    local FILE=$3
    [ ! -f "$FILE" ] && echoErr "ERROR: File '$FILE' does NOT exist, nothing can be set!"
    local ADDED=$(setLastLineByPrefix "$PREFIX" "$TEXT" "$FILE")
    if [ "$ADDED" == "false" ] ; then
        echo "$TEXT" >> $FILE
    elif [ "$ADDED" != "true" ] ; then
        echoErr "ERROR: Failed to set line or apped to '$FILE'"
        return 1
    fi
}

function setEnv() {
    local ENV_NAME=$(delWhitespaces "$1")
    local ENV_VALUE=$2
    local ENV_FILE=$3 && ([ -z "$ENV_FILE" ] || [ ! -f $ENV_FILE ]) && ENV_FILE="/etc/profile"
    
    if [ ! -z "$ENV_NAME" ] && [ -f $ENV_FILE ] ; then
        local LINE_NR=$(getLastLineByPrefix "${ENV_NAME}=" "$ENV_FILE" 2> /dev/null || echo "-1")
        [[ $LINE_NR -lt 0 ]] && LINE_NR=$(getLastLineByPrefix "export ${ENV_NAME}=" "$ENV_FILE" 2> /dev/null || echo "-1")

        # add quotes if string has any whitespaces
        echoInfo "INFO: Appending env '$ENV_NAME' with value '$ENV_VALUE' to file '$ENV_FILE'"
        if [ -z "$ENV_VALUE" ] || [[ "$ENV_VALUE" = *" "* ]] ; then
            echo "export ${ENV_NAME}=\"${ENV_VALUE}\"" >> $ENV_FILE
        else
            echo "export ${ENV_NAME}=${ENV_VALUE}" >> $ENV_FILE
        fi

        if [[ $LINE_NR -ge 0 ]] ; then
            echoWarn "WARNING: Wiped old env '$ENV_NAME' at line '$LINE_NR' in the file '$ENV_FILE'"
            sed -i"" "${LINE_NR}d" $ENV_FILE
        fi
        return 0
    else
        echoErr "ERROR: Failed to set environment variable '$ENV_NAME' in '$ENV_FILE'"
        return 1
    fi
}

function setGlobEnv() {
    local ENV_NAME=$1
    local ENV_VALUE=$2
    
    local GLOB_SRC="source /etc/profile"
    local SUDOUSER="${SUDO_USER}" && [ "$SUDOUSER" == "root" ] && SUDOUSER=""
    local USERNAME="${USER}" && [ "$USERNAME" == "root" ] && USERNAME=""
    local LOGNAME=$(logname 2> /dev/null echo "") && [ "$LOGNAME" == "root" ] && LOGNAME=""

    local TARGET="/$LOGNAME/.bashrc"
    if [ ! -z "$LOGNAME" ] && [ -f  $TARGET ] ; then
        local LINE_NR=$(getLastLineByPrefix "$GLOB_SRC" "$TARGET" 2> /dev/null || echo "-1")
        [[ $LINE_NR -lt 0 ]] && ( echo $GLOB_SRC >> $TARGET || echoErr "ERROR: Failed to append global env source file to '$TARGET'" )
    fi

    TARGET="/$USERNAME/.bashrc"
    if [ ! -z "$USERNAME" ] && [ -f $TARGET ] ; then
        local LINE_NR=$(getLastLineByPrefix "$GLOB_SRC" "$TARGET" 2> /dev/null || echo "-1")
        [[ $LINE_NR -lt 0 ]] && ( echo $GLOB_SRC >> $TARGET || echoErr "ERROR: Failed to append global env source file to '$TARGET'" )
    fi

    TARGET="/$SUDOUSER/.bashrc"
    if [ ! -z "$SUDOUSER" ] && [ -f $TARGET ] ; then
        local LINE_NR=$(getLastLineByPrefix "$GLOB_SRC" "$TARGET" 2> /dev/null || echo "-1")
        [[ $LINE_NR -lt 0 ]] && ( echo $GLOB_SRC >> $TARGET || echoErr "ERROR: Failed to append global env source file to '$TARGET'" )
    fi

    TARGET="/root/.bashrc"
    if [ -f $TARGET ] ; then
        local LINE_NR=$(getLastLineByPrefix "$GLOB_SRC" "$TARGET" 2> /dev/null || echo "-1")
        [[ $LINE_NR -lt 0 ]] && ( echo $GLOB_SRC >> $TARGET || echoErr "ERROR: Failed to append global env source file to '$TARGET'" )
    fi

    TARGET="~/.zshrc"
    if [ -f $TARGET ] ; then
        local LINE_NR=$(getLastLineByPrefix "$GLOB_SRC" "$TARGET" 2> /dev/null || echo "-1")
        [[ $LINE_NR -lt 0 ]] && ( echo $GLOB_SRC >> $TARGET || echoErr "ERROR: Failed to append global env source file to '$TARGET'" )
    fi

    TARGET="~/.bashrc"
    if [ -f $TARGET ] ; then
        local LINE_NR=$(getLastLineByPrefix "$GLOB_SRC" "$TARGET" 2> /dev/null || echo "-1")
        [[ $LINE_NR -lt 0 ]] && ( echo $GLOB_SRC >> $TARGET || echoErr "ERROR: Failed to append global env source file to '$TARGET'" )
    fi

    TARGET="~/.profile"
    if [ -f $TARGET ] ; then
        local LINE_NR=$(getLastLineByPrefix "$GLOB_SRC" "$TARGET" 2> /dev/null || echo "-1")
        [[ $LINE_NR -lt 0 ]] && ( echo $GLOB_SRC >> $TARGET || echoErr "ERROR: Failed to append global env source file to '$TARGET'" )
    fi

    setEnv "$ENV_NAME" "$ENV_VALUE" "/etc/profile"
}

function setGlobPath() {
    local VAL="$1"
    GLOBENV_SRC=/etc/profile

    ($(isNullOrEmpty "$VAL")) && echoWarn "WARNING: Value is undefined, no need to append anything to PATH at '$GLOBENV_SRC"
    
    local LINE_NR=$(getLastLineByPrefix "PATH=" "$GLOBENV_SRC" 2> /dev/null || echo "-1")
    [[ $LINE_NR -lt 0 ]] && LINE_NR=$(getLastLineByPrefix "export PATH=" "$GLOBENV_SRC" 2> /dev/null || echo "-1")

    if [[ $LINE_NR -lt 0 ]] ; then
        echoInfo "INFO: Global PATH variable was NOT fount at '$GLOBENV_SRC', appending..."
        echo "export PATH=\"\$PATH\"" >> $GLOBENV_SRC
    fi

    local EXPORT_PREFIX="false" && LINE_NR=$(getLastLineByPrefix "PATH=" "$GLOBENV_SRC" 2> /dev/null || echo "-1")
    [[ $LINE_NR -lt 0 ]] && LINE_NR=$(getLastLineByPrefix "export PATH=" "$GLOBENV_SRC" 2> /dev/null || echo "-1") && EXPORT_PREFIX="true"
    [[ $LINE_NR -lt 0 ]] && echoErr "ERROR: Failed to locate PATH variable at '$GLOBENV_SRC'" && return 1

    PATH_CONTENT=$(sed "${LINE_NR}q;d" "$GLOBENV_SRC")
    # remove quotes and variable key prefix
    [ "${EXPORT_PREFIX}" == "false" ] && PATH_CONTENT=$(echo ${PATH_CONTENT#"PATH="} | tr -d '"')
    [ "${EXPORT_PREFIX}" == "true" ] && PATH_CONTENT=$(echo ${PATH_CONTENT#"export PATH="} | tr -d '"')

    if ($(isSubStr "$PATH_CONTENT" "$VAL")); then
        echoWarn "WARNING: PATH already contains value '$VAL', nothing to append"
    else
        PATH_CONTENT="${PATH_CONTENT}:$VAL"
    fi

    setGlobEnv "PATH" "$PATH_CONTENT"
}

# set or update global line of text by prefix
# setGlobLine "mount -t drvfs C:" "mount -t drvfs C: /mnt/c"
function setGlobLine() {
    local PREFIX="$1"
    local VALUE="$2"
    GLOBENV_SRC=/etc/profile

    ($(isNullOrEmpty "$PREFIX")) && echoErr "ERROR: Prefix was undefined, there is nothing to append to '$GLOBENV_SRC" && return 1
    
    local LINE_NR=$(getLastLineByPrefix "$PREFIX" "$GLOBENV_SRC" 2> /dev/null || echo "-1")
    if [[ $LINE_NR -lt 0 ]] ; then
        echoWarn "WARNING: Global line was NOT fount at '$GLOBENV_SRC'"
        echoInfo "INFO: Appending '$VALUE' to the file '$GLOBENV_SRC'"
        echo "$VALUE" >> $GLOBENV_SRC
        return 0
    fi

    echoWarn "WARNING: Wiped old line '$LINE_NR' in the file '$GLOBENV_SRC'"
    sed -i"" "${LINE_NR}d" $GLOBENV_SRC
    
    if ($(isNullOrEmpty "$VALUE")) ; then
        echoInfo "INFO: There was nothing defined to append to the file '$GLOBENV_SRC'"
    else
        echoInfo "INFO: Appending '$VALUE' to the file '$GLOBENV_SRC'"
        echo "$VALUE" >> $GLOBENV_SRC
    fi
}

function loadGlobEnvs() {
    . /etc/profile
}

# crossenvLink "$KIRA_BIN/CDHelper-<arch>/CDHelper" "/usr/local/bin/CDhelper"
# NOTE: the <arch> tag will be replaced by arm64 & amd64
function crossenvLink() {
    local SOURCE_PATH=$1
    local DESTINATION_PATH=$2

    local FULL_SRC_PATH_ARM64="${SOURCE_PATH/<arch>/arm64}"
    local FULL_SRC_PATH_AMD64="${SOURCE_PATH/<arch>/amd64}"

    if [ -f $FULL_SRC_PATH_ARM64 ] && [ -f $FULL_SRC_PATH_AMD64 ] ; then
        cat > $DESTINATION_PATH << EOL
#!/usr/bin/env bash
set -e

if [[ "\$(uname -m)" == *"arm"* ]] || [[ "\$(uname -m)" == *"aarch"* ]] ; then
    if [ -z "$@" ] ; then
        $FULL_SRC_PATH_ARM64
    else
        $FULL_SRC_PATH_ARM64 "\$@"
    fi
else
    if [ -z "$@" ] ; then
        $FULL_SRC_PATH_AMD64
    else
        $FULL_SRC_PATH_AMD64 "\$@"
    fi
fi
EOL
        chmod -v 555 "$DESTINATION_PATH" "$FULL_SRC_PATH_AMD64" "$FULL_SRC_PATH_ARM64"
    else
        [ ! -f $FULL_SRC_PATH_ARM64 ] && echoErr "ERROR: Could NOT find arm64 relese: '$FULL_SRC_PATH_ARM64'" 
        [ ! -f $FULL_SRC_PATH_AMD64 ] && echoErr "ERROR: Could NOT find amd64 relese: '$FULL_SRC_PATH_AMD64'"
        return 1
    fi
}

# allow to execute finctions directly from file
if declare -f "$1" > /dev/null ; then
  # call arguments verbatim
  "$@"
fi