#!/usr/bin/env bash
# QUICK EDIT: FILE="/tmp/bash-utils.sh" && rm -fv $FILE && nano $FILE && chmod 555 $FILE && /tmp/bash-utils.sh bashUtilsSetup
# NOTE: For this script to work properly the KIRA_GLOBS_DIR env variable should be set to "/var/kiraglob" or equivalent & the directory should exist
REGEX_DNS="^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}$"
REGEX_IP="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
REGEX_NODE_ID="^[a-f0-9]{40}$"
REGEX_TXHASH="^[a-fA-F0-9]{64}$"
REGEX_SHA256="^[a-fA-F0-9]{64}$"
REGEX_MD5="^[a-fA-F0-9]{32}$"
REGEX_INTEGER="^-?[0-9]+$"
REGEX_NUMBER="^[+-]?([0-9]*[.])?([0-9]+)?$"
REGEX_PUBLIC_IP='^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(?<!172\.(16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31))(?<!127)(?<!^10)(?<!^0)\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(?<!192\.168)(?<!172\.(16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31))\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(?<!\.255$)(?<!\b255.255.255.0\b)(?<!\b255.255.255.242\b)$'
REGEX_CIRD="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\/([0-9]|[1-2][0-9]|3[0-2])$"
REGEX_KIRA="^(kira)[a-zA-Z0-9]{39}$"
REGEX_VERSION="^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-?)([a-zA-Z]+)?(\.?([0-9]+)?)$"
REGEX_CID="^(Qm[1-9A-HJ-NP-Za-km-z]{44,}|b[A-Za-z2-7]{58,}|B[A-Z2-7]{58,}|z[1-9A-HJ-NP-Za-km-z]{48,}|F[0-9A-F]{50,})$"
# NOTE: Important! in the REGEX_URL the ' quote character must be used instead of ", do NOT modify this string
REGEX_URL1='[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'
REGEX_URL2="^(https?|ftp|file)://$REGEX_URL1"

function bashUtilsVersion() {
    bashUtilsSetup "version" 2> /dev/null || bash-utils bashUtilsSetup "version"
}

# this is default installation script for utils
# ./bash-utils.sh bashUtilsSetup "/var/kiraglob"
function bashUtilsSetup() {
    local BASH_UTILS_VERSION="v0.3.6"
    local COSIGN_VERSION="v1.13.1"
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

        echo "INFO: Loaded utils from '$UTILS_SOURCE', installing bash-utils & setting up glob dir in '$KIRA_GLOBS_DIR'..."

        if [ "$VERSION" != "$BASH_UTILS_VERSION" ] ; then
            bash-utils echoErr "ERROR: Self check version mismatch, expected '$BASH_UTILS_VERSION', but got '$VERSION'"
            return 1
        elif [ "$UTILS_SOURCE" == "$UTILS_DESTINATION" ] ; then
            bash-utils echoErr "ERROR: Installation source script and destination can't be the same"
            return 1
        elif [ ! -f "$UTILS_SOURCE" ] ; then
            bash-utils echoErr "ERROR: utils source was NOT found"
            return 1
        else
            mkdir -p "/usr/local/bin" "/bin"
            cp -fv "$UTILS_SOURCE" "$UTILS_DESTINATION"
            cp -fv "$UTILS_SOURCE" "/usr/local/bin/bash-utils"
            cp -fv "$UTILS_SOURCE" "/usr/local/bin/bu"
            chmod +x "$UTILS_DESTINATION" "/usr/local/bin/bash-utils" "/bin/bu"

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

            mkdir -p "$KIRA_GLOBS_DIR"

            bash-utils setGlobEnv KIRA_GLOBS_DIR "$KIRA_GLOBS_DIR"
            bash-utils setGlobEnv KIRA_TOOLS_SRC "$UTILS_DESTINATION"
            bash-utils setGlobPath "/usr/local/bin"
            bash-utils setGlobPath "/bin"

            local AUTOLOAD_SET=$(bash-utils getLastLineByPrefix "source $UTILS_DESTINATION" /etc/profile 2> /dev/null || echo "-1")

            if [[ $AUTOLOAD_SET -lt 0 ]] ; then
                echo "source $UTILS_DESTINATION || echo \"ERROR: Failed to load kira bash-utils from '$UTILS_DESTINATION'\"" >> /etc/profile
            fi

            bu loadGlobEnvs
            echoInfo "INFO: SUCCESS!, Installed kira bash-utils $(bashUtilsVersion)"
        fi

        if (! $(isCommand cosign)) ; then
            echoWarn "WARNING: Cosign tool is not installed, setting up $COSIGN_VERSION..."
            if [[ "$(uname -m)" == *"ar"* ]] ; then ARCH="arm64"; else ARCH="amd64" ; fi && \
             PLATFORM=$(uname) && FILE_NAME=$(echo "cosign-${PLATFORM}-${ARCH}" | tr '[:upper:]' '[:lower:]') && \
             TMP_FILE="/tmp/${FILE_NAME}.tmp" && rm -fv "$TMP_FILE" && \
             wget https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/$FILE_NAME -O "$TMP_FILE" && \
             chmod +x -v "$TMP_FILE" && mv -fv "$TMP_FILE" /usr/local/bin/cosign

             cosign version
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
    local val=$(bash-utils toLower "$1")
    if [ -z "$val" ] || [ "$val" == "null" ] || [ "$val" == "nil" ] ; then echo "true" ; else echo "false" ; fi
}

function delWhitespaces() {
    echo "$1" | tr -d '\011\012\013\014\015\040'
}

function isNullOrWhitespaces() {
    isNullOrEmpty $(bash-utils delWhitespaces "$1")
}

function isKiraAddress() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_KIRA ]] && echo "true" || echo "false" ; fi
}

function isTxHash() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_TXHASH ]] && echo "true" || echo "false" ; fi
}

function isSHA256() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_SHA256 ]] && echo "true" || echo "false" ; fi
}

function isMD5() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_MD5 ]] && echo "true" || echo "false" ; fi
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
        local VAR="false" && ($(isDns "$1")) && VAR="true"
        [ "$VAR" != "true" ] && ($(isIp "$1")) && VAR="true"
        echo $VAR
    fi
}

# Notation check "xxx.xxx.xxx.xxx/xx"
# e.g.: isCIDR 172.22.24.212/20
function isCIDR() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_CIRD ]] && echo "true" || echo "false" ; fi
}


function isInteger() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ $1 =~ $REGEX_INTEGER ]] && echo "true" || echo "false" ; fi
}

function isBoolean() {
    if ($(bash-utils isNullOrEmpty "$1")) ; then echo "false" ; else
        local val=$(bash-utils toLower "$1")
        if [ "$val" == "false" ] || [ "$val" == "true" ] ; then echo "true"
        else echo "false" ; fi
    fi
}

function isNodeId() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_NODE_ID ]] && echo "true" || echo "false" ; fi
}

function isNumber() {
     if ($(bash-utils isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_NUMBER ]] && echo "true" || echo "false" ; fi
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
    local MNEMONIC=$(echo "$1" | xargs 2> /dev/null || echo -n "")
    local COUNT=$(echo "$MNEMONIC" | wc -w 2> /dev/null || echo -n "")
    (! $(isNaturalNumber $COUNT)) && COUNT=0

    # Ensure that string only contains words
    if [[ $MNEMONIC =~ ^[[:alpha:][:space:]]*$ ]] ; then
        if (( $COUNT % 3 == 0 )) && [[ $COUNT -ge 12 ]] ; then echo "true" ; else echo "false" ; fi
    else
        echo "false"
    fi
}

function isVersion {
  [[ "$1" =~ $REGEX_VERSION ]] && echo "true" || echo "false"
}

function isCID() {
    if ($(isNullOrEmpty "$1")) ; then echo "false" ; else [[ "$1" =~ $REGEX_CID ]] && echo "true" || echo "false" ; fi
}

function date2unix() {
    local DATE_TMP=""
    [ -z "$*" ] && DATE_TMP="$(timeout 1 cat 2> /dev/null || echo "")" || DATE_TMP="$*"
    DATE_TMP=$(echo "$DATE_TMP" | xargs 2> /dev/null || echo -n "")
    if (! $(isNullOrWhitespaces "$DATE_TMP")) && (! $(isNaturalNumber $DATE_TMP)) ; then
        DATE_TMP=$(date -d "$DATE_TMP" +"%s" 2> /dev/null || echo "0")
    fi

    ($(isNaturalNumber "$DATE_TMP")) && echo "$DATE_TMP" || echo "0"
}

function isPortOpen() {
    local ADDRESS=$1
    local PORT=$2
    local TIMEOUT=$3
    (! $(isNaturalNumber $TIMEOUT)) && TIMEOUT=1
    if (! $(isDnsOrIp $ADDRESS)) || (! $(isPort $PORT)) ; then echo "false"
    elif timeout $TIMEOUT nc -z $ADDRESS $PORT ; then echo "true"
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

function isSameFile() {
    local FILE1="$1"
    local FILE2="$2"
    if [ ! -z $FILE1 ] && [ -f $FILE1 ] && [ ! -z $FILE2 ] && [ -f $FILE2 ] ; then
        echo $(cmp --silent $FILE1 $FILE2 && echo "true" || echo "false")
    else
        echo "false"
    fi
}

# Example use case: [[ $(versionToNumber "v0.0.0.3") -lt $(versionToNumber "v1.0.0.2") ]] && echo true || echo false
function versionToNumber() {
    local version=""
    [ -z "$1" ] && version="$(timeout 1 cat 2> /dev/null || echo "")" || version="$1"
    version=$(echo "$version" | tr -d [a-z,A-Z] | sed "s/-././g" | sed "s/+/./g" | sed "s/-//g" | tr -d ' ')
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

function strLength() {
    [ "$1" == "-e" ] && echo "2" && return 0
    local result=""
    [ -z "$1" ] && result="0" || result=$(echo "$1" | awk '{print length}') || result=-1
    ($(isNumber "$result")) && echo $result || echo -1
}

function strFirstN() {
    local string="$1"
    local n="$2" && (! $(isNaturalNumber $n)) && n=3
    local string_len=$(strLength "$string")
    [[ $string_len -le $n ]] && echo "$string" || echo "${string:0:n}"
}

function strLastN() {
    local string="$1"
    local n="$2" && (! $(isNaturalNumber $n)) && n=0
    local string_len=$(strLength "$string")
    [[ $string_len -le $n ]] && echo "$string" || echo "${string: -n}"
}

# shortens string if possible by taking N prefix and N suffix characters and combining it with separator
# e.g. strShort "123456789" 1 "..."" -> 1...9 
function strShort() {
    local string="$1"
    local trim_len="$2" && ( (! $(isNaturalNumber $trim_len)) || [[ $trim_len -le 0 ]]  ) && trim_len=3
    local separator="$3" && [ -z "$separator" ] && separator="..."
    local string_len=$(strLength "$string")
    local separator_len=$(strLength "$separator")
    local final_len=$(((trim_len * 2) + separator_len ))
    [[ $string_len -le $final_len ]] && echo "$string" || echo "$(strFirstN "$string" $trim_len)${separator}$(strLastN "$string" $trim_len)"
}

# shorten string to exact number of characters with a separator
# e.g. strShort 123456789" 5 '.' -> 1...9
function strShortN() {
    local string="$1"
    local max_len="$2" && ( (! $(isNaturalNumber $max_len)) || [[ $max_len -le 0 ]]  ) && echo "" && return 0
    local separator="$3" && ( [ -z "$separator" ] || [[ $(strLength "$separator") -gt 1 ]] ) && separator="." 
    local string_len=$(strLength "$string")
    if [[ $max_len -le 0 ]] ; then
        echo ""
    elif [[ $max_len -ge $string_len ]] ; then  # same or greater lenght, skip processing
        echo "$string"
    elif [[ $max_len -le 1 ]] ; then # if sting can be just a single char then just display separator: '.'
        echo "$separator"
    elif [[ $max_len -eq 2 ]] ; then # if sting can be just a single char then just display separator: 'a.'
        echo "$(strFirstN "$string" 1)$separator"
    elif [[ $max_len -eq 3 ]] ; then  # if sting can be just 3 char then just display first and last:  'a..'
        echo "$(strFirstN "$string" 1)${separator}${separator}"
    elif [[ $max_len -eq 4 ]] ; then # if sting can be just 4 char then just display 1 first and 1 last: 'a..b'
        echo "$(strFirstN "$string" 1)${separator}${separator}${separator}"
    else
        local side_len=$(((max_len - 3) / 2 ))
        local final_len=$(((side_len * 2) + 3))
        [[ $final_len -ne $max_len ]] && echo "$(strFirstN "$string" $((side_len + 1)))${separator}${separator}${separator}$(strLastN "$string" $side_len)" || echo "$(strShort "$string" $side_len "${separator}${separator}${separator}")"
    fi
}

# repeats string N times
# e.g.: strRepeat "a" 3 -> aaa
strRepeat(){
    local string="$1"
    local n="$2" && ( (! $(isNaturalNumber $n)) || [[ $n -le 0 ]]  ) && n=0
    local output=""
    for i in $(seq 1 $n); do
      output="$output$string"
    done
    echo "$output"
}

# fixes string to specific length to the left with filler padding
# e.g.: echo "| $(strFixL "123456789" 15) |" -> | 123456789       |
function strFixL() {
    local string="$1"
    local max_len="$2" && ( (! $(isNaturalNumber $max_len)) || [[ $max_len -le 0 ]]  ) && max_len=0
    local separator="$3" && [ -z "$separator" ] && separator="."
    local filler="$4" && [ -z "$filler" ] && filler=" "
    filler=$(strRepeat "$filler" $max_len)
    echo "$(strFirstN "$(strShortN "$string" $max_len "$separator")$filler" $max_len)"
}

# fixes string to specific length to the left with filler padding
# e.g.: echo "| $(strFixR "123456789" 15) |" -> |       123456789 |
function strFixR() {
    local string="$1"
    local max_len="$2" && ( (! $(isNaturalNumber $max_len)) || [[ $max_len -le 0 ]]  ) && max_len=0
    local separator="$3" && [ -z "$separator" ] && separator="."
    local filler="$4" && [ -z "$filler" ] && filler=" "
    filler=$(strRepeat "$filler" $max_len)
    echo "$(strLastN "${filler}$(strShortN "$string" $max_len "$separator")" $max_len)"
}

# fixes string to specific length to the center with filler padding
# e.g.: echo "| $(strFixC "123456789" 15) |" -> |    123456789    |
function strFixC() {
    local string="$1"
    local max_len="$2" && ( (! $(isNaturalNumber $max_len)) || [[ $max_len -le 0 ]]  ) && max_len=0
    local separator="$3" && [ -z "$separator" ] && separator="."
    local filler="$4" && [ -z "$filler" ] && filler=" "
    local filler_extr=$(strRepeat "$filler" $max_len)
    local string_len=$(strLength "$string")

    if [[ $string_len -ge $max_len ]] ; then
        echo "$(strFixL "$string" "$max_len" "$separator" "$filler")"
    else
        local remaining=$((max_len - string_len))
        local side_len=$((remaining / 2))
        local filler_extr=$(strRepeat "$filler" $side_len)
        [[ $((remaining % 2)) -eq 0 ]] && echo "${filler_extr}${string}${filler_extr}" || echo "${filler_extr}${string}${filler_extr}${filler}"
    fi
}

function strStartsWith() {
    local string="$1"
    local prefix="$2"
    local string_len=$(strLength "$string")
    local prefix_len=$(strLength "$prefix")
    if [[ $prefix_len -eq $string_len ]] && [[ $string_len -ge 1 ]] ; then
        [ "$string" == "$prefix" ] && echo "true" && return 0 || echo "false" && return 0
    elif [[ $prefix_len -le $string_len ]] && [[ $prefix_len -ge 1 ]] && [[ $string_len -ge 1 ]] ; then
        local substr="${string:0:$prefix_len}"
        [ "$substr" == "$prefix" ] && echo "true" && return 0 || echo "false" && return 0
    fi
    echo "false"
}

function strEndsWith() {
    local string="$1"
    local suffix="$2"
    local string_len=$(strLength "$string")
    local suffix_len=$(strLength "$suffix")
    if [[ $suffix_len -eq $string_len ]] && [[ $string_len -ge 1 ]] ; then
        [ "$string" == "$suffix" ] && echo "true" && return 0 || echo "false" && return 0
    elif [[ $suffix_len -le $string_len ]] && [[ $suffix_len -ge 1 ]] && [[ $string_len -ge 1 ]] ; then
        local n="-${suffix_len}"
        local substr="${string:$n}"
        [ "$substr" == "$suffix" ] && echo "true" && return 0 || echo "false" && return 0
    fi
    echo "false"
}

# splits string by specific character and takes n'th element (indexed starting at 0)
# e.g.: strSplitTakeN , 2 "a,b,c"
function strSplitTakeN() {
    local IFS="$1"
    local arr=($3)
    echo "${arr[$2]}"
}

# getArgs --test="lol1" --tes-t="lol-l" --test2="lol 2" -e=ok -t=ok2
function getArgs() {
    for arg in "$@" ; do
        ($(strStartsWith "$arg" "-")) && (! $(strStartsWith "$arg" "--")) && arg="-${arg}"
        if ($(strStartsWith "$arg" "--")) && [[ "$arg" == *"="* ]] && [[ "$arg" != "--="* ]] && [[ "$arg" != "-="* ]] ; then
            local arg_len=$(strLength "$arg")
            local prefix=$(echo $arg | cut -d'=' -f1)
            local prefix_len=$(strLength "$prefix")
            local n="-$((arg_len - prefix_len - 1))"
            local val="${arg:$n}"
            prefix="$(echo $prefix  | sed -z 's/^-*//')"
            local key=$(echo "$prefix" | tr '-' '_')
            echoInfo "$key='$val'"
            eval $key="'$val'"
        else
            echoErr "ERROR: Invalid argument '$arg', missing name, '--' and/or '=' operators"
            return 1
        fi
    done
}

# get default network interface
function getNetworkIface() {
    echo "$(netstat -rn 2> /dev/null | grep -m 1 UG | awk '{print $8}' | xargs 2> /dev/null || echo -n "")"
}

# get network interfaces
function getNetworkIfaces() {
    echo "$(ifconfig | cut -d ' ' -f1 | tr ':' '\n' | awk NF)"
}

function getPublicIp() {
    local public_ip=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com +time=5 +tries=1 2> /dev/null | awk -F'"' '{ print $2}' 2> /dev/null || echo -n "")
    ( ! $(isDnsOrIp "$public_ip")) && public_ip=$(dig +short @resolver1.opendns.com myip.opendns.com +time=5 +tries=1 2> /dev/null | awk -F'"' '{ print $1}' 2> /dev/null || echo -n "")
    ( ! $(isDnsOrIp "$public_ip")) && public_ip=$(dig +short @ns1.google.com -t txt o-o.myaddr.l.google.com -4 2> /dev/null | xargs 2> /dev/null || echo -n "")
    ( ! $(isDnsOrIp "$public_ip")) && public_ip=$(timeout 3 curl --silent https://ipinfo.io/ip | xargs 2> /dev/null || echo -n "")
    ( ! $(isDnsOrIp "$public_ip")) && echo "" || echo "$public_ip"
}

# returns ip of the defined local network interface otherwise checks default
# .e.g getLocalIp "$(globGet IFACE)"
function getLocalIp() {
    local default_iface="$1"
    [ -z "$default_iface" ] && default_iface=$(getDefaultNetworkIface)
    local local_ip=$(/sbin/ifconfig "$default_iface" | grep -i mask | awk '{print $2}' | cut -f2 2> /dev/null || echo -n "")
    ( ! $(isDnsOrIp "$local_ip")) && local_ip=$(hostname -I | awk '{ print $1}' 2> /dev/null || echo "0.0.0.0")
    ($(isDnsOrIp "$local_ip")) && echo "$local_ip" || echo "0.0.0.0"
}

# Host list: https://ipfs.github.io/public-gateway-checker
# Given file CID downloads content from a known public IPFS gateway
# ipfsGet <file> <CID>
function ipfsGet() {
    local OUT_PATH=$1
    local FILE_CID=$2
    local PUB_URL=""

    local TIMEOUT=30

    if ($(isCID "$FILE_CID")) ; then
        echoInfo "INFO: Cleaning up '$OUT_PATH' and searching for available gatewys..."

        PUB_URL="https://gateway.ipfs.io/ipfs/${FILE_CID}"
        if ( [ "$DOWNLOAD_SUCCESS" != "true" ] && [[ $(urlContentLength "$PUB_URL" $TIMEOUT) -gt 1 ]] ) ; then
            wget "$PUB_URL" -O "$OUT_PATH" && DOWNLOAD_SUCCESS="true" || echoWarn "WARNING: Faild download from gateway.ipfs.io :("
        fi

        PUB_URL="https://dweb.link/ipfs/${FILE_CID}"
        if ( [ "$DOWNLOAD_SUCCESS" != "true" ] && [[ $(urlContentLength "$PUB_URL" $TIMEOUT) -gt 1 ]] ) ; then
            wget "$PUB_URL" -O "$OUT_PATH" && DOWNLOAD_SUCCESS="true" || echoWarn "WARNING: Faild download from dweb.link :("
        fi

        PUB_URL="https://ipfs.joaoleitao.org/ipfs/${FILE_CID}" 
        if ( [ "$DOWNLOAD_SUCCESS" != "true" ] && [[ $(urlContentLength "$PUB_URL" $TIMEOUT) -gt 1 ]] ) ; then
            wget "$PUB_URL" -O "$OUT_PATH" && DOWNLOAD_SUCCESS="true" || echoWarn "WARNING: Faild download from ipfs.joaoleitao.org :("
        fi

        PUB_URL="https://ipfs.kira.network/ipfs/${FILE_CID}"
        if ( [ "$DOWNLOAD_SUCCESS" != "true" ] && [[ $(urlContentLength "$PUB_URL" $TIMEOUT) -gt 1 ]] ) ; then
            wget "$PUB_URL" -O "$OUT_PATH" && DOWNLOAD_SUCCESS="true" || echoWarn "WARNING: Faild download from ipfs.joaoleitao.org :("
        fi

        PUB_URL="https://ipfs.kira.network/ipfs/${FILE_CID}"
        if ( [ "$DOWNLOAD_SUCCESS" != "true" ] && [[ $(urlContentLength "$PUB_URL" $TIMEOUT) -gt 1 ]] ) ; then
            wget "$PUB_URL" -O "$OUT_PATH" && DOWNLOAD_SUCCESS="true" || echoWarn "WARNING: Faild download from ipfs.joaoleitao.org :("
        fi

        PUB_URL="https://ipfs.snggle.com/ipfs/${FILE_CID}"
        if ( [ "$DOWNLOAD_SUCCESS" != "true" ] && [[ $(urlContentLength "$PUB_URL" $TIMEOUT) -gt 1 ]] ) ; then
            wget "$PUB_URL" -O "$OUT_PATH" && DOWNLOAD_SUCCESS="true" || echoWarn "WARNING: Faild download from ipfs.joaoleitao.org :("
        fi

        if ( [ "$DOWNLOAD_SUCCESS" != "true" ] || [ ! -f "$OUT_PATH" ] ) ; then
            echoErr "ERROR: Failed to locate or download '$FILE_CID' file from any public IPFS gateway :("
            return 1
        else
            echoInfo "INFO: Success, file '$FILE_CID' was downloaded to '$OUT_PATH' from '$PUB_URL'"
        fi
    else
        echoErr "ERROR: Specified file CID '$FILE_CID' is NOT valid"
        return 1
    fi
}

# Allows to safely download file from external resources by hash verification or cosign file signature
# In the case where cosign verification is used the "<url>.sig" URL must exist
# safeWget <file> <url> <hash>
# safeWget <file> <url> <pubkey-path>
# safeWget <file> <url> <hash>,<hash>,<hash>...
# safeWget <file> <url> <CID>
function safeWget() {
    local OUT_PATH=$1
    local FILE_URL=$2
    local EXPECTED_HASH=$3

    # we need to use MD5 for TMP files to ensure that we download the file again if URL changes
    local OUT_NAME=$(echo "$OUT_PATH" | md5)
    local TMP_DIR=/tmp/downloads
    local TMP_PATH="$TMP_DIR/${OUT_NAME}"

    local PUB_URL=""
    local SIG_URL="${FILE_URL}.sig"
    local TMP_PATH_SIG="$TMP_DIR/${OUT_NAME}.sig"
    local TMP_PATH_PUB="$TMP_DIR/${OUT_NAME}.pub"

    mkdir -p "$TMP_DIR"
    rm -fv "$TMP_PATH_SIG" "$TMP_PATH_PUB"

    local FILE_HASH=$(sha256 $TMP_PATH)
    local EXPECTED_HASH_ARR=($(echo "$EXPECTED_HASH" | tr ',' '\n'))
    local EXPECTED_HASH_FIRST="${EXPECTED_HASH_ARR[0]}"
    local COSIGN_PUB_KEY=""
    local PUB_URL=""
    local DOWNLOAD_SUCCESS="false"

    if (! $(isCommand cosign)) ; then
        echoErr "ERROR: Cosign tool is not installed, please install version v1.13.1 or later."
        return 1
    fi

    if (! $(isSHA256 "$EXPECTED_HASH_FIRST")) ; then
        if ($(isCID "$EXPECTED_HASH_FIRST")) ; then
            echoInfo "INFO: Detected IPFS CID, searching available gatewys..."
            COSIGN_PUB_KEY="$TMP_PATH_PUB"
            ipfsGet "$COSIGN_PUB_KEY" "$EXPECTED_HASH_FIRST"

            if ($(isFileEmpty $COSIGN_PUB_KEY)); then
                echoErr "ERROR: Failed to locate or download public key file '$EXPECTED_HASH_FIRST' from any public IPFS gateway :("
                return 1
            fi
        elif (! $(isFileEmpty "$EXPECTED_HASH_FIRST")) ; then
            echoInfo "INFO: Detected public key file"
            COSIGN_PUB_KEY="$EXPECTED_HASH_FIRST"
        fi

        if (! $(isFileEmpty $COSIGN_PUB_KEY)) || ($(urlExists "$COSIGN_PUB_KEY")) ; then
            echoWarn "WARNING: Attempting to fetch signature file..."
            wget "$SIG_URL" -O $TMP_PATH_SIG
        else
            echoErr "ERROR: Public key was not found in '$COSIGN_PUB_KEY'"
            return 1
        fi
    else
        echoInfo "INFO: One of the following checksums will be used to verify file integrity: '${EXPECTED_HASH_ARR[*]}'"
    fi

    local COSIGN_VERIFIED="false"
    if ( (! $(isFileEmpty $COSIGN_PUB_KEY)) || ($(urlExists "${COSIGN_PUB_KEY}" 1)) ) && (! $(isFileEmpty $TMP_PATH)) ; then
        echoInfo "INFO: Using cosign to verify temporary file integrity..."
        COSIGN_VERIFIED="true"  
        cosign verify-blob --key="$COSIGN_PUB_KEY" --signature="$TMP_PATH_SIG" "$TMP_PATH" || COSIGN_VERIFIED="false"

        if [ "$COSIGN_VERIFIED" == "true" ] ; then
            echoInfo "INFO: Cosign successfully verified integrity of an already existing temporary file"
            EXPECTED_HASH="$FILE_HASH"
        else
            echoInfo "INFO: Cosign failed to verify temporary file integrity"
            EXPECTED_HASH=""
        fi
    fi

    EXPECTED_HASH_ARR=($(echo "$EXPECTED_HASH" | tr ',' '\n'))
    local HASH_MATCH="false"
    for hash in "${EXPECTED_HASH_ARR[@]}" ; do
        if [ "$FILE_HASH" == "$hash" ] && ($(isSHA256 "$hash")); then
            HASH_MATCH="true"
            echoInfo "INFO: No need to download, file with the hash '$FILE_HASH' was already found in the '$TMP_DIR' directory"
            [ "$TMP_PATH" != "$OUT_PATH" ] && cp -fv $TMP_PATH $OUT_PATH
            break
        fi
    done
    
    if [ "$HASH_MATCH" == "false" ] ; then
        rm -fv $OUT_PATH
        wget "$FILE_URL" -O $TMP_PATH
        [ "$TMP_PATH" != "$OUT_PATH" ] && cp -fv $TMP_PATH $OUT_PATH
        FILE_HASH=$(sha256 $OUT_PATH)
    fi

    COSIGN_VERIFIED="false"
    if [ "$HASH_MATCH" == "false" ] && (! $(isFileEmpty $COSIGN_PUB_KEY)) && (! $(isFileEmpty $OUT_PATH)) ; then


        echoInfo "INFO: Using cosign to verify final file integrity..."
        COSIGN_VERIFIED="true"
        cosign verify-blob --key="$COSIGN_PUB_KEY" --signature="$TMP_PATH_SIG" "$OUT_PATH" || COSIGN_VERIFIED="false"

        if [ "$COSIGN_VERIFIED" == "true" ] ; then
            echoInfo "INFO: Cosign successfully verified integrity of downloaded file"
            EXPECTED_HASH="$FILE_HASH"
        else
            echoInfo "INFO: Cosign failed to verify integrity of downloaded file"
            EXPECTED_HASH="cosign"
        fi
    fi

    EXPECTED_HASH_ARR=($(echo "$EXPECTED_HASH" | tr ',' '\n'))
    HASH_MATCH="false"
    for hash in "${EXPECTED_HASH_ARR[@]}" ; do
        if [ "$FILE_HASH" == "$hash" ] && ($(isSHA256 "$hash")) ; then
            HASH_MATCH="true"
            break
        fi
    done

    if ($(isFileEmpty $OUT_PATH)) ; then
        echoErr "ERROR: Failed download from '$FILE_URL', file is exmpty or was NOT found!"
        return 1
    elif [ "$HASH_MATCH" != "true" ] ; then
        rm -fv $OUT_PATH || echoErr "ERROR: Failed to delete '$OUT_PATH'"
        echoErr "ERROR: Safe download filed: '$FILE_URL' -x-> '$OUT_PATH'"
        echoErr "ERROR: Expected hash (one of): '${EXPECTED_HASH_ARR[*]}', but got '$FILE_HASH'"
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

# allowed modes: 'default', 'short', 'long'
function getArch() {
    local mode="$1" && mode="$(bash-utils toLower $mode)"
    local ARCH=$(uname -m)
    if [[ "$ARCH" == *"arm"* ]] || [[ "$ARCH" == *"aarch"* ]] ; then
        echo "arm64"
    elif [[ "$ARCH" == *"x64"* ]] || [[ "$ARCH" == *"x86_64"* ]] || [[ "$ARCH" == *"amd64"* ]] || [[ "$ARCH" == *"amd"* ]] ; then
        if [ "$mode" == "short" ] ; then
            echo "x64"
        else
            echo "amd64"
        fi
    else
        echo "$ARCH"
    fi
}

function getArchX() {
    echo $(bash-utils getArch 'short')
}

function getPlatform() {
    echo "$(delWhitespaces $(bash-utils toLower $(uname)))"
}

function tryMkDir {
    for kg_var in "$@" ; do
        kg_var=$(echo "$kg_var" | tr -d '\011\012\013\014\015\040' 2>/dev/null || echo -n "")
        [ -z "$kg_var" ] && continue
        [ "$(bash-utils toLower "$kg_var")" == "-v" ] && continue
        
        if [ -f "$kg_var" ] ; then
            if [ "$(bash-utils toLower "$1")" == "-v" ] ; then
                rm -f "$kg_var" 2> /dev/null || : 
                [ ! -f "$kg_var" ] && echo "removed file '$kg_var'" || echo "failed to remove file '$kg_var'"
            else
                rm -f 2> /dev/null || :
            fi
        fi

        if [ "$(bash-utils toLower "$1")" == "-v" ]  ; then
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

function jsonAttributes() {
    local FIN="$1"
    if [ ! -z "$FIN" ] ; then
        if (! $(isFileEmpty "$FIN")) ; then
            python3 -c "
import json,sys;
def ptrintAttributes(root, obj):
    for key in obj:
        val=obj[key]
        if str(type(val)) == \"<class 'dict'>\":
            ptrintAttributes(root + '.' + key, val)
        else:
            print((root + '.' + key)[1:])
f=open('$FIN','r');obj=json.load(f);ptrintAttributes('', obj);f.close()"
        fi
    else
        cat | python3 -c "
import json,sys;
def ptrintAttributes(root, obj):
    for key in obj:
        val=obj[key]
        if str(type(val)) == \"<class 'dict'>\":
            ptrintAttributes(root + '.' + key, val)
        else:
            print((root + '.' + key)[1:])
obj=json.load(sys.stdin); ptrintAttributes('', obj)"
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
    [ "$(bash-utils toLower "$VALUE")" == "null" ] && VALUE="None"
    [ "$(bash-utils toLower "$VALUE")" == "true" ] && VALUE="True"
    [ "$(bash-utils toLower "$VALUE")" == "false" ] && VALUE="False"
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
    [ "$(bash-utils toLower "$VALUE")" == "null" ] && VALUE="None"
    [ "$(bash-utils toLower "$VALUE")" == "true" ] && VALUE="True"
    [ "$(bash-utils toLower "$VALUE")" == "false" ] && VALUE="False"
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

function isURL() {
    if ($(isNullOrEmpty "$1")) || ($(isVersion "$1")) ; then echo "false" ; 
    else ( [[ "$1" =~ $REGEX_URL1 ]] || [[ "$1" =~ $REGEX_URL2 ]]  ) && echo "true" || echo "false" ; fi
}

# e.g. urlExists "18.168.78.192:11000/download/peers.txt" 10
function urlExists() {
    local timeout="$2" && (! $(isNaturalNumber $timeout)) && timeout=10
    if ($(isNullOrEmpty "$1")) ; then echo "false"
    elif curl -r0-0 --fail --silent -m $timeout "$1" >/dev/null; then echo "true"
    else echo "false" ; fi
}

# TODO: Investigate 0 output
# urlContentLength 18.168.78.192:11000/api/snapshot 10
function urlContentLength() {
    local timeout="$2" && (! $(isNaturalNumber $timeout)) && timeout=10
    local VAL=$(curl --fail $1 --dump-header /dev/fd/1 --silent -m $timeout  2> /dev/null | grep -i Content-Length -m 1 2> /dev/null | awk '{print $2}' 2> /dev/null || echo -n "")
    # remove invisible whitespace characters
    VAL=$(echo ${VAL%$'\r'})
    (! $(isNaturalNumber $VAL)) && VAL=0
    echo $VAL
}

function globName() {
    echo $(echo "$(bash-utils toLower "$1")" | tr -d '\011\012\013\014\015\040' | md5sum | awk '{ print $1 }')
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
    [ "$(bash-utils toLower "$ISACT")" == "active" ] && echo "true" || echo "false"
}

function isWSL {
    echo "$(isSubStr "$(uname -a)" "microsoft-standard-WSL")"
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

# sets global var with user selection, default var name is OPTION
# e.g.: pressToContinue TEST a b c
function pressToContinue {
    local glob_var_name="OPTION"
    local var_len=0
    for kg_var in "$@" ; do
        kg_var=$(echo "$kg_var" | tr -d '\011\012\013\014\015\040' 2>/dev/null || echo -n "")
        [[ $(strLength "$kg_var") -ge 2 ]] && glob_var_name=$kg_var && break
    done

    if ($(isNullOrEmpty "$1")) ; then
        read -n 1 -s 
        globSet "$glob_var_name" ""
    else
        while : ; do
            local OPTION=""
            local FOUND=false
            read -n 1 -s OPTION
            OPTION=$(bash-utils toLower "$OPTION")
            for kg_var in "$@" ; do
                kg_var=$(echo "$kg_var" | tr -d '\011\012\013\014\015\040' 2>/dev/null || echo -n "")
                [ "$(bash-utils toLower "$kg_var")" == "$OPTION" ] && globSet "$glob_var_name" "$OPTION" && FOUND=true && break
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

# print with colours, to restore default use 'tput reset' or 'tput sgr0'
# recognisable color types: [bla]ck, [red], [gre]en, [yel]low, [blu], [mag]enta, [cya]n
# recognisable font types: [bol]d, [dim], [ita]lic, [und]er, [bli]nk, [inv]erse, [str]ike, [per]sustent, [sto]re, [res]tore, [cle]ar
# recognisable intensities: [bri]gth (true/1), [dar]k (false/0)
# e.g.: echoNC "<font>;<foreground>;<bacground>;<fr-intensity>;<bg-intensity>;<persistent>;<store/restore>" "test text"
# e.g.: echoNC "bli;whi;bla;d;b;false" "test text"
# e.g.: echoNC "bli;whi;bla;d;b;false" "test text"
# echoC "sto;blu" "|---------$(echoC "res;gre" "lol")---------|"
function echoNC() {
    local IFS=";"
    local arr=($1)
    local font="${arr[0]}"
    local fgrnd="${arr[1]}"
    local bgrnd="${arr[2]}"
    local fint="${arr[3]}"
    local bint="${arr[4]}"
    local persistent="${arr[5]}"
    local store="${arr[6]}"
    local text="$2"

    ([ -z "$persistent" ] || [ "$persistent" == "false" ] || [ "$persistent" == "0" ]) && persistent="false"
    ([ "$persistent" == "true" ] || [ "$persistent" == "1" ] || [ "$persistent" == "per" ] || [ "$persistent" == "p" ]) && persistent="true"

    ([ -z "$store" ] || [ "$store" == "false" ] || [ "$store" == "0" ]) && store="false"
    ([ "$store" == "store" ] || [ "$store" == "sto" ] || [ "$store" == "s" ]) && store="store"
    ([ "$store" == "restore" ] || [ "$store" == "res" ] || [ "$store" == "r" ]) && store="restore"
    ([ "$store" == "clear" ] || [ "$store" == "cle" ] || [ "$store" == "c" ]) && store="clear"

    ([ -z "$font" ] || [ "$font" == "nor" ] || [ "$font" == "nul" ] || [ "$font" == "true" ]) && font=0
    [ "$font" == "bol" ] && font=1
    [ "$font" == "dim" ] && font=2
    [ "$font" == "ita" ] && font=3
    [ "$font" == "und" ] && font=4
    [ "$font" == "bli" ] && font=5
    [ "$font" == "inv" ] && font=7
    ( [ "$font" == "str" ] || [ "$font" == "false" ] ) && font=9
    [ "$font" == "per" ] && persistent="true" && font=0
    [ "$font" == "sto" ] && store="store" && font=0
    [ "$font" == "res" ] && store="restore" && font=0
    [ "$font" == "cle" ] && store="clear" && font=0
    
    ([ "$fgrnd" == "bla" ] || [ "$fgrnd" == "false" ])&& fgrnd=30
    [ "$fgrnd" == "red" ] && fgrnd=31
    [ "$fgrnd" == "gre" ] && fgrnd=32
    [ "$fgrnd" == "yel" ] && fgrnd=33
    [ "$fgrnd" == "blu" ] && fgrnd=34
    [ "$fgrnd" == "mag" ] && fgrnd=35
    [ "$fgrnd" == "cya" ] && fgrnd=36
    ([ -z "$fgrnd" ] || [ "$fgrnd" == "whi" ] || [ "$fgrnd" == "true" ]) && fgrnd=37

    ([ -z "$bgrnd" ] || [ "$bgrnd" == "bla" ] || [ "$fgrnd" == "true" ]) && bgrnd=40
    [ "$bgrnd" == "red" ] && bgrnd=41
    [ "$bgrnd" == "gre" ] && bgrnd=42
    [ "$bgrnd" == "yel" ] && bgrnd=43
    [ "$bgrnd" == "blu" ] && bgrnd=44
    [ "$bgrnd" == "mag" ] && bgrnd=45
    [ "$bgrnd" == "cya" ] && bgrnd=46
    ([ "$bgrnd" == "whi" ] || [ "$fgrnd" == "false" ]) && bgrnd=47

    if [[ $fgrnd -ge 90 ]] ; then
        ([ "$fint" == "dar" ] || [ "$fint" == "d" ] || [ "$fint" == "0" ] || [ "$fint" == "false" ]) && \
        fgrnd=$((fgrnd - 60))
    fi

    ( [ -z "$fint" ] || [ "$fint" == "bri" ] || [ "$fint" == "b" ] || [ "$fint" == "1" ] || [ "$fint" == "true" ]) && \
        fgrnd=$((fgrnd + 60))

    ( [ "$bint" == "bri" ] || [ "$bint" == "b" ] || [ "$bint" == "1" ] || [ "$bint" == "true" ]) && \
        bgrnd=$((bgrnd + 60))

    if [[ $bgrnd -ge 100 ]] ; then
        ([ "$bint" == "dar" ] || [ "$bint" == "d" ] || [ "$bint" == "0" ] || [ "$bint" == "false" ]) && \
        bgrnd=$((bgrnd - 60))
    fi

    local new_config="${font};${fgrnd};${bgrnd}m"

    if [ "$persistent" == "true" ] ; then
        echo -en "\e[0m\e[${new_config}${text}"
    else
        echo -en "\e[0m\e[${new_config}${text}\e[0m"
    fi

    if [ "$store" == "store" ] ; then
        globSet "kg_echoNC_" "$new_config"
    elif [ "$store" == "restore" ] ; then
        local old_config="$(globGet "kg_echoNC_")"
        [ ! -z "$old_config" ] && echo -en "\e[0m\e[${old_config}" || tput sgr0
    elif [ "$store" == "clear" ] ; then
        tput sgr0
    fi
}
function echoC() {
    echo "$(echoNC "$1" "${2}")"
}

# blue popup
function echoPop() {
    echo -e "\e[0m\e[94;1m${1}\e[0m"
}
# green console log
function echoLog() {
    echo -e "\e[0m\e[92;1m${1}\e[0m"
}
# light blue info
function echoInfo() {
    echo -e "\e[0m\e[36;1m${1}\e[0m"
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

function echoNPop() {
    echo -en "\e[0m\e[94;1m${1}\e[0m"
}
function echoNLog() {
    echo -en "\e[0m\e[92;1m${1}\e[0m"
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

function getNLineBySubStr() {
    local INDEX=$1
    local SUBSTR=$2
    local FILE=$3
    INDEX="$((INDEX-1))"
    if ($(isNullOrWhitespaces "$SUBSTR")) || ($(isNullOrWhitespaces "$FILE")) || [ ! -f $FILE ] ; then echo "-1" ; else
        SUBSTR=${SUBSTR//"="/"\="}
        SUBSTR=${SUBSTR//"/"/"\/"}
        SUBSTR=${SUBSTR//"["/"\["}
        SUBSTR=${SUBSTR//"*"/"\*"}
        local lines=$(sed -n "/${SUBSTR}/=" $FILE)
        if ($(isNullOrWhitespaces "$lines")) ; then echo "-1" ; else
            local lineArr=($(echo $lines))
            local lineNr=${lineArr[$INDEX]}
            ($(isNaturalNumber "$lineNr")) && echo "$lineNr" || echo "-1"
        fi
    fi
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

# getLastLineByPSubStr <prefix> <file>
function getLastLineByPSubStr() {
    getNLineBySubStr "0" "$1" "$2"
}

function getLastLineByPrefix() {
    getNLineByPrefix "0" "$1" "$2"
}

function getFirstLineBySubStr() {
    getNLineBySubStr "1" "$1" "$2"
}

function getFirstLineByPrefix() {
    getNLineByPrefix "1" "$1" "$2"
}

function setLineByNumber() {
    local INDEX=$1
    local TEXT=$2
    local FILE=$3
    [ ! -f "$FILE" ] && echoErr "ERROR: File '$FILE' does NOT exist, nothing can be set!"
    if [ -z "$TEXT" ] ; then
        # delete line if text is empty
        sed -i"" "${INDEX}d" $FILE
    else
        # set line if text is NOT eopty
        sed -i"" "$INDEX c\
$TEXT" $FILE
    fi
}

function setNLineBySubStr() {
    local INDEX=$1
    local SUBSTR=$2
    local TEXT=$3
    local FILE=$4
    local LINE=$(getNLineBySubStr "$INDEX" "$SUBSTR" "$FILE")
    if [[ $LINE -ge 0 ]] ; then
        setLineByNumber "$LINE" "$TEXT" "$FILE"
        echo "true"
    else
        echo "false"
    fi
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

function setLastLineBySubStr() {
    setNLineBySubStr "0" "$1" "$2" "$3"
}

function setLastLineByPrefix() {
    setNLineByPrefix "0" "$1" "$2" "$3"
}

function setFirstLineBySubStr() {
    setNLineBySubStr "1" "$1" "$2" "$3"
}

function setFirstLineByPrefix() {
    setNLineByPrefix "1" "$1" "$2" "$3"
}

function setLastLineBySubStrOrAppend() {
    local SUBSTR=$1
    local TEXT=$2
    local FILE=$3
    [ ! -f "$FILE" ] && echoErr "ERROR: File '$FILE' does NOT exist, nothing can be set!"
    local ADDED=$(setLastLineBySubStr "$SUBSTR" "$TEXT" "$FILE")
    if [ "$ADDED" == "false" ] ; then
        echo "$TEXT" >> $FILE
    elif [ "$ADDED" != "true" ] ; then
        echoErr "ERROR: Failed to set line or apped to '$FILE'"
        return 1
    fi
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

function getFirstLineByPrefixAfterPrefix() {
    local tag="$1"
    local prefix="$2"
    local file="$3"

    local result=0
    local index=0
    local min_line=0
    (! $(bash-utils isNullOrWhitespaces "$tag")) && \
     min_line=$(bash-utils getFirstLineByPrefix "$tag" "$file")

    if [[ $min_line -le -1 ]] ; then
        result="-1"
    else
        while [[ result -le min_line ]] ; do
            index="$((index+1))"
            result=$(bash-utils getNLineByPrefix $index "$prefix" "$file")
            [[ $result -le -1 ]] && break
        done
    fi

    echo "$result"
}

# Gets var names by index, e.g. getTomlVarName 36 ./example.toml -> [<tag>] <name>
function getTomlVarName() {
    local index=$1
    local file=$2
    local tag="[base]"
    local name=""
    local cnt=0
    local line=""
    mapfile rows < $file
    for row in "${rows[@]}"; do
       line=$(echo "$row" | tr -d '\011\012\013\014\015\040')
       if [[ $line = \[*\] ]] ; then
           tag="$line"
           continue
       elif  [ -z "$line" ] || [[ $line = \#* ]] ; then
            continue
       elif [[ $line = *=* ]] ; then
           name=$(echo "$line" | cut -d= -f1 | xargs)
           if  [ ! -z "$name" ] ; then
               cnt="$((cnt+1))"
               [[ $cnt -eq $index ]] && echo "$tag $name" && break
           fi
       fi
    done
}

# getTomlVarNames ./example.toml
function getTomlVarNames() {
    local file=$1
    local tag="[base]"
    local name=""
    local result=""
    local cnt=0
    local line=""
    mapfile rows < $file
    for row in "${rows[@]}"; do
       line=$(echo "$row" | tr -d '\011\012\013\014\015\040')
       if [[ $line = \[*\] ]] ; then
           tag="$line"
           continue
       elif  [ -z "$line" ] || [[ $line = \#* ]] ; then 
            continue
       elif [[ $line = *=* ]] ; then
           name=$(echo "$line" | cut -d= -f1 | xargs)
           [ ! -z "$name" ] && echo "$tag $name"
       fi
    done
}

# setTomlVar <tag> <name> <value> <file>
function setTomlVar() {
    local VAR_TAG=$(echo "$1" | tr -d '\011\012\013\014\015\040\133\135' | xargs)
    local VAR_NAME=$(delWhitespaces "$2")
    local VAR_VALUE="$3"
    local VAR_FILE=$4

    [ ! -z "$VAR_TAG" ] && VAR_TAG="[${VAR_TAG}]"
    [ "$VAR_TAG" == "[base]" ] && echoWarn "WARNING: Base tag detected!" && VAR_TAG=""
    
    ([ -z "$VAR_FILE" ] || [ ! -f $VAR_FILE ]) && \
     echoErr "ERROR: File '$VAR_FILE' does NOT exist, can't upsert '$VAR_NAME' variable" && return 1
    
    local MIN_LINE_NR=$(getFirstLineByPrefixAfterPrefix "" "$VAR_TAG" "$VAR_FILE")
    local LINE_NR=$(getFirstLineByPrefixAfterPrefix "$VAR_TAG" "$VAR_NAME =" "$VAR_FILE")
    local MAX_LINE_NR=$(getFirstLineByPrefixAfterPrefix "$VAR_TAG" "[" "$VAR_FILE")
    ( [[ $LINE_NR -le 0 ]] || ( [[ $MAX_LINE_NR -gt 0 ]] && [[ $LINE_NR -ge $MAX_LINE_NR ]] ) ) && \
     echoErr "ERROR: File '$VAR_FILE' does NOT contain a variable name '$VAR_NAME' occuring afer the tag '$VAR_TAG' (line $MIN_LINE_NR), but before the next tag (line $MAX_LINE_NR)" && \
     LINE_NR=-1 && return 1

    if [ ! -z "$VAR_NAME" ] && [ -f $VAR_FILE ] && [ $LINE_NR -ge 1 ] ; then
        
        if ($(isNullOrWhitespaces "$VAR_VALUE")) ; then
            echoWarn "WARNING: Brackets will be added, value '$VAR_VALUE' is empty or a seq. of whitespaces"
            VAR_VALUE="\"$VAR_VALUE\""
        elif ( ($(strStartsWith "$VAR_VALUE" "\"")) && ($(strEndsWith "$VAR_VALUE" "\"")) ) ; then
            : # nothing to do, quotes already present
        elif ( (! $(strStartsWith "$VAR_VALUE" "[")) || (! $(strEndsWith "$VAR_VALUE" "]")) ) ; then
            if  ($(isSubStr "$VAR_VALUE" " ")) ; then
                echoWarn "WARNING: Brackets will be added, value '$VAR_VALUE' contains whitespaces"
                VAR_VALUE="\"$VAR_VALUE\""
            elif ( (! $(isBoolean "$VAR_VALUE")) && (! $(isNumber "$VAR_VALUE")) ) ; then
                echoWarn "WARNING: Brackets will be added, value '$VAR_VALUE' in neither a number or boolean"
                VAR_VALUE="\"$VAR_VALUE\""       
            fi
        fi

        echoInfo "INFO: Updating '$VAR_TAG' '$VAR_NAME' with value '$VAR_VALUE' in the file '$VAR_FILE' at line '$LINE_NR'"
        setLineByNumber "$LINE_NR" "$VAR_NAME = $VAR_VALUE" "$VAR_FILE"
        return 0
    else
        echoErr "ERROR: Failed to set variable '$VAR_NAME' in '$VAR_FILE'"
        return 1
    fi
}

# reads last variable occurance from a file
# getVar "PATH" /etc/profile
function getVar() {
    local VAR_NAME="$(delWhitespaces "$1")"
    local VAR_FILE="$2"
    if [ ! -z "$VAR_NAME" ] && [ -f $VAR_FILE ] ; then
        local LINE_NR=$(getLastLineByPrefix "${VAR_NAME}=" "$VAR_FILE" 2> /dev/null || echo "-1")
        [[ $LINE_NR -lt 0 ]] && LINE_NR=$(getLastLineByPrefix "export ${VAR_NAME}=" "$VAR_FILE" 2> /dev/null || echo "-1")

        if [[ $LINE_NR -ge 0 ]] ; then
            local line=$(sed "${LINE_NR}q;d" $VAR_FILE)
            line="$( cut -d '=' -f 2- <<< "$line" )"

            if ($(strStartsWith "$line" "\"")) && ($(strEndsWith "$line" "\"")) && ($(isSubStr "$line" " ")) ; then
                line=$(sed -e 's/^"//' -e 's/"$//' <<<"$line")
            fi
            echo "$line"
            return 0
        fi
    fi

    return 1
}

function tryGetVar() {
    getVar "$1" "$2" 2> /dev/null || echo ""
} 

# setVar <name> <value> <file>
function setVar() {
    local VAR_NAME=$(delWhitespaces "$1")
    local VAR_VALUE=$2
    local VAR_FILE=$3
    
    ([ -z "$VAR_FILE" ] || [ ! -f $VAR_FILE ]) && echoErr "ERROR: File '$VAR_FILE' does NOT exist, can't usert '$VAR_NAME' variable"
    
    if [ ! -z "$VAR_NAME" ] && [ -f $VAR_FILE ] ; then
        local LINE_NR=$(getLastLineByPrefix "${VAR_NAME}=" "$VAR_FILE" 2> /dev/null || echo "-1")

        # add quotes if string has any whitespaces
        echoInfo "INFO: Appending var '$VAR_NAME' with value '$VAR_VALUE' to file '$VAR_FILE'"
        if [ -z "$VAR_VALUE" ] || [[ "$VAR_VALUE" = *" "* ]] ; then
            echo "${VAR_NAME}=\"${VAR_VALUE}\"" >> $VAR_FILE
        else
            echo "${VAR_NAME}=${VAR_VALUE}" >> $VAR_FILE
        fi

        if [[ $LINE_NR -ge 0 ]] ; then
            echoWarn "WARNING: Wiped old var '$VAR_NAME' at line '$LINE_NR' in the file '$VAR_FILE'"
            sed -i"" "${LINE_NR}d" $VAR_FILE
        fi
        return 0
    else
        echoErr "ERROR: Failed to set environment variable '$VAR_NAME' in '$VAR_FILE'"
        return 1
    fi
}

function trySetVar() {
    setVar "$1" "$2" "$3" 2> /dev/null || :
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
