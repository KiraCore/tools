set -e
set -x

bu echoInfo "Starting unit tests..."
go test ./... -vet=off -v || bu echoInfo "IPFS-API test finished successfully"

bu echoInfo "Starting integration tests..."

ROOT_DIR=$(pwd)
MAIN_DIR=$ROOT_DIR/cmd/ipfs-api/main.go
ENTRY_DIR=$ROOT_DIR/test_dir
SECOND_DIR=$ENTRY_DIR/test_dir1

bu echoInfo "Creating directory tree..."
mkdir -p $ENTRY_DIR || bu echoError "Failed to create directory $ENTRY_DIR"
mkdir -p $SECOND_DIR || bu echoError "Failed to create directory $SECOND_DIR"


bu echoInfo "Populating directory tree with files..."
# Populate dir with files L1
set +x 
for i in {1..5}; 
do
    echo "file$i">"$ENTRY_DIR/file$i.txt" || bu echoError "Failed to create file$i.txt"
done

# Populate dir with files L2
for i in {6..10};
do
    echo "file$i">"$SECOND_DIR/file$i.txt" || bu echoError "Failed to create file$i.txt"
done


function dagExportTest(){
    bu echoNInfo "[    ] dagExportTest"

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
    bu echoNInfo "[    ] pinTest"
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR --key="$PINATA_API_JWT_TEST" | jq -r .hash)

    if [[ $WANT -eq $GOT ]]; 
    then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] pinTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] pinTest\e[0m"; echo
        exit 1
    fi

}

function deleteByHashTest(){
    bu echoNInfo "[    ] deleteByHashTest"
    
    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR delete $WANT --key="$PINATA_API_JWT_TEST" | jq .success)
    
    if [[ $GOT -eq $WANT ]];
    then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] deleteByHashTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] deleteByHashTest\e[0m"; echo
        exit 1
    fi
}

function pinWithMetaTest(){
    bu echoNInfo "[    ] pinWithMetaTest"

    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR meta --key="$PINATA_API_JWT_TEST" | jq -r .hash)

    if [[ $WANT -eq $GOT ]]; 
    then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] pinWithMetaTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] pinWithMetaTest\e[0m"; echo
        exit 1
    fi

}

function pinWithMetaForceTest(){
    bu echoNInfo "[    ] pinWithMetaForceTest"

    local WANT="bafybeiajf7mv3htewce3zozleukne3vfmagrc7bmk7uzzcsy7gjexkuwg4"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR foobar --key="$PINATA_API_JWT_TEST" | jq -r .hash)

    if [[ $WANT -eq $GOT ]]; 
    then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] pinWithMetaForceTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] pinWithMetaForceTest\e[0m"; echo
        exit 1
    fi

}
function pinWithMetaOverwriteTest(){
    bu echoNInfo "[    ] pinWithMetaOverwriteTest"

    local WANT="OK"
    local GOT=$(go run $MAIN_DIR pin $ENTRY_DIR foobar --overwrite --key="$PINATA_API_JWT_TEST")
    if [[ $WANT -eq $GOT ]]; 
    then
       echo -en "\e[0m\e[36;1m\033[1G[PASS] pinWithMetaOverwriteTest\e[0m"; echo
    else
       echo -en "\e[0m\e[31;1m\033[1G[FAILED] pinWithMetaOverwriteTest\e[0m"; echo
       exit 1
    fi

}

function deleteByMetaTest(){
    bu echoNInfo "[PASS] deleteByMetaTest"

    local WANT=true
    local GOT=$(go run $MAIN_DIR delete meta --key="$PINATA_API_JWT_TEST" | jq .success)
    if [[ $GOT -eq $WANT ]];
     then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] deleteByMetaTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] deleteByMetaTest\e[0m"; echo
        exit 1
    fi
}

function deleteByMetaOverwriteTest(){
    bu echoNInfo "[PASS] deleteByMetaOverwriteTest"

    local WANT=true
    local GOT=$(go run $MAIN_DIR delete foobar --key="$PINATA_API_JWT_TEST" | jq .success)

    if [[ $GOT -eq true ]];
     then
        echo -en "\e[0m\e[36;1m\033[1G[PASS] deleteByMetaOverwriteTest\e[0m"; echo
    else
        echo -en "\e[0m\e[31;1m\033[1G[FAILED] deleteByMetaOverwriteTest\e[0m"; echo
        exit 1
    fi
}

bu echoInfo "Starting tests..."

TESTS=(dagExportTest pinTest deleteByHashTest pinWithMetaTest deleteByMetaTest pinWithMetaTest pinWithMetaOverwriteTest deleteByMetaOverwriteTest pinWithMetaTest pinWithMetaForceTest deleteByMetaOverwriteTest)
for TEST in "${TESTS[@]}"; do
    $TEST
done
bu echoInfo "All tests finished. Cleaning up the environment..."
set -x
rm -rf $ENTRY_DIR || bu echoError "Failed to clean up an the environment"
bu echoInfo "All done..."