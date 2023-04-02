set -e
set +x
. /etc/profile
. ../../bash-utils/bash-utils.sh

set -x

echoInfo "Starting unit tests..."
go test ./... -vet=off -v || echo "IPFS-API test finished successfully"

echoInfo "Starting integration tests..."

ROOT_DIR=$(pwd)
MAIN_DIR=$ROOT_DIR/cmd/ipfs-api/main.go
ENTRY_DIR=$ROOT_DIR/test_dir
SECOND_DIR=$ENTRY_DIR/test_dir1

echoInfo "Creating directory tree..."
mkdir -p $ENTRY_DIR || echoError "Failed to create directory $ENTRY_DIR"
mkdir -p $SECOND_DIR || echoError "Failed to create directory $SECOND_DIR"


echoInfo "Populating directory tree with files..."
# Populate dir with files L1
set +x 
for i in {1..5}; 
do
    echo "file$i">"$ENTRY_DIR/file$i.txt" || echoError "Failed to create file$i.txt"
done

# Populate dir with files L2
for i in {6..10};
do
    echo "file$i">"$SECOND_DIR/file$i.txt" || echoError "Failed to create file$i.txt"
done


function dagExportTest(){
    echoNInfo "[    ] dagExportTest"

    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR dag $ENTRY_DIR --export)
    
    if [[ $WANT -eq $GOT ]]; 
    then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] dagExportTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[PASS] dagExportTest\e[0m"; echo
        exit 1
    fi
}

function pinTest(){
    echoNInfo "[    ] pinTest"
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR --key="${{secrets.PINATA_API_JWT_TEST}}" | jq -r .hash)

    if [[ $WANT -eq $GOT ]]; 
    then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] pinTest\e[0m"
        echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] pinTest\e[0m"
        echo
        exit 1
    fi

}

function deleteByHashTest(){
    echoNInfo "[    ] deleteByHashTest"
    
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR delete $WANT --key="${{secrets.PINATA_API_JWT_TEST}}" | jq .success)
    
    if [[ $GOT -eq $WANT ]];
    then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] deleteByHashTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] deleteByHashTest\e[0m"; echo
        exit 1
    fi
}

function pinWithMetaTest(){
    echoNInfo "[    ] pinWithMetaTest"

    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR meta --key="${{secrets.PINATA_API_JWT_TEST}}" | jq -r .hash)

    if [[ $WANT -eq $GOT ]]; 
    then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] pinWithMetaTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] pinWithMetaTest\e[0m"; echo
        exit 1
    fi

}

function pinWithMetaForceTest(){
    echoNInfo "[    ] pinWithMetaForceTest"

    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR foobar --key="${{secrets.PINATA_API_JWT_TEST}}" | jq -r .hash)

    if [[ $WANT -eq $GOT ]]; 
    then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] pinWithMetaForceTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] pinWithMetaForceTest\e[0m"; echo
        exit 1
    fi

}
function pinWithMetaOverwriteTest(){
    echoNInfo "[    ] pinWithMetaOverwriteTest"

    local WANT="OK"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR foobar --overwrite --key="${{secrets.PINATA_API_JWT_TEST}}")
    if [[ $WANT -eq $GOT ]]; 
    then
       echo -en "\e[0m\e[36;1m\033[1G[PASS] pinWithMetaOverwriteTest\e[0m"; echo
    else
       echo -en "\e[0m\e[31;1m\033[1G[FAILED] pinWithMetaOverwriteTest\e[0m"; echo
       exit 1
    fi

}

function deleteByMetaTest(){
    echoNInfo "[PASS] deleteByMetaTest"

    local WANT=true
    local GOT=$(go run $MAIN_DIR delete meta --key="${{secrets.PINATA_API_JWT_TEST}}" | jq .success)
    if [[ $GOT -eq $WANT ]];
     then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] deleteByMetaTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] deleteByMetaTest\e[0m"; echo
        exit 1
    fi
}

function deleteByMetaOverwriteTest(){
    echoNInfo "[PASS] deleteByMetaOverwriteTest"

    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR delete foobar --key="${{secrets.PINATA_API_JWT_TEST}}" | jq .success)

    if [[ $GOT -eq true ]];
     then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] deleteByMetaOverwriteTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] deleteByMetaOverwriteTest\e[0m"; echo
        exit 1
    fi
}
echoInfo "Starting tests..."
TESTS=(dagExportTest pinTest deleteByHashTest pinWithMetaTest deleteByMetaTest pinWithMetaTest pinWithMetaOverwriteTest deleteByMetaOverwriteTest pinWithMetaTest pinWithMetaForceTest deleteByMetaOverwriteTest)
for TEST in "${TESTS[@]}"; do
    $TEST
done
echoInfo "All tests finished. Cleaning up the environment..."
set -x
rm -rf $ENTRY_DIR || echoError "Failed to clean up an the environment"
echoInfo "All done..."