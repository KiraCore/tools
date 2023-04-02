#!/bin/bash

set -e
set -x

echo -e "\e[0m\e[36;1mStarting unit tests...\e[0m"

go test ./... -vet=off -v || echo "IPFS-API test finished successfully"

echo -e "\e[0m\e[36;1mStarting integration tests...\e[0m"
ROOT_DIR=$(pwd)
MAIN_DIR=$ROOT_DIR/cmd/ipfs-api/main.go
ENTRY_DIR=$ROOT_DIR/test_dir
SECOND_DIR=$ENTRY_DIR/test_dir1

echo -e "\e[0m\e[36;1mCreating directory tree...\e[0m"
mkdir -p $ENTRY_DIR || echo -e "\e[0m\e[31;1mFailed to create directory $ENTRY_DIR\e[0m"
mkdir -p $SECOND_DIR || echo -e "\e[0m\e[31;1mFailed to create directory $SECOND_DIR\e[0m"

echo -e "\e[0m\e[36;1mPopulating directory tree with files...\e[0m"

# Populate dir with files L1
set +x 
for i in {1..5}; 
do
    echo "file$i">"$ENTRY_DIR/file$i.txt" || echo -e "\e[0m\e[31;1mFailed to create file$i.txt\e[0m"
done

# Populate dir with files L2
for i in {6..10};
do
    echo "file$i">"$SECOND_DIR/file$i.txt" || echo -e "\e[0m\e[31;1mFailed to create file$i.txt\e[0m"
done


function dagExportTest(){
    echo -en "\e[0m\e[36;1m[    ] dagExportTest\e[0m"

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
    echo -en "\e[0m\e[36;1m[    ] pinTest\e[0m"
    
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
    echo -en "\e[0m\e[36;1m[    ] deleteByHashTest\e[0m"
    
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
    echo -en "\e[0m\e[36;1m[    ] pinWithMetaTest\e[0m"

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
    echo -en "\e[0m\e[36;1m[    ] pinWithMetaForceTest\e[0m"

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
    echo -en "\e[0m\e[36;1m[    ] pinWithMetaOverwriteTest\e[0m"

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
    echo -en "\e[0m\e[36;1m[PASS] deleteByMetaTest\e[0m"

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
    echo -en "\e[0m\e[36;1m[PASS] deleteByMetaOverwriteTest\e[0m"

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
echo -e "\e[0m\e[36;1mStarting tests...\e[0m"

TESTS=(dagExportTest pinTest deleteByHashTest pinWithMetaTest deleteByMetaTest pinWithMetaTest pinWithMetaOverwriteTest deleteByMetaOverwriteTest pinWithMetaTest pinWithMetaForceTest deleteByMetaOverwriteTest)
for TEST in "${TESTS[@]}"; do
    $TEST
done

echo -e "\e[0m\e[36;1mAll tests finished. Cleaning up the environment...\e[0m"

set -x

rm -rf $ENTRY_DIR || echo -e "\e[0m\e[31;1mFailed to clean up the environment\e[0m"

echo -e "\e[0m\e[36;1mAll done...\e[0m"
