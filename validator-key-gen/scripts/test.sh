#!/usr/bin/env bash

# This script tests address formation and MD5 checksums for the output files.
# It also cleans up the files created during the test.

# Mnemonic seed
MNEMONIC="\"over where supreme taste warrior morning perfect memory glove stereo taste trip sheriff fringe weather finger segment under arrange gain warrior olympic urge vacant\""

# Expected output addresses
OUTPUT[0]="\"kira103luqf09g5juctmvrmgnw5gmn2mhpelqhcsy84\"" 
OUTPUT[1]="\"kiravaloper103luqf09g5juctmvrmgnw5gmn2mhpelqy7v8le\"" 
OUTPUT[2]="\"kiravalcons103luqf09g5juctmvrmgnw5gmn2mhpelqsdlmnc\""

# Address types
ADRTYPE[0]="Account address" 
ADRTYPE[1]="Validator address" 
ADRTYPE[2]="Consensus address"

# Input commands to generate the addresses
INPUT[0]="go run . --mnemonic=${MNEMONIC} --accadr" 
INPUT[1]="go run . --mnemonic=${MNEMONIC} --valadr" 
INPUT[2]="go run . --mnemonic=${MNEMONIC} --consadr"

# Function to test address formation
testadr(){
    echo "Testing address formation:"
    for i in $(seq 0 $((${#INPUT[@]} - 1))); do
        IN=$(eval "${INPUT[$i]}")
        OUT="${OUTPUT[$i]}"
        ADR="${ADRTYPE[$i]}"
        
        if [ "$in" = "$out" ]; then
                echo "[PASSED]: $ADR"
            else
                echo "[FAILED]: malformed $ADR. Want $OUT, got $In"
                return 1
        fi
    done
    return 0
}

# Expected MD5 checksums
MD5[0]="\"8a100779d27e5ae2098498674df32f8b\"" 
MD5[1]="\"d14df3851190d360953989e296db3cf3\"" 
MD5[2]="\"7ab595fe3d53672ac918a351bcaa10b5\""

# Output file paths
FILES[0]="./valkey" 
FILES[1]="./nodekey" 
FILES[2]="./keyid"

# Commands to generate output files
CMD[0]="go run . --mnemonic=${MNEMONIC} --valkey=${FILES[0]}" 
CMD[1]="go run . --mnemonic=${MNEMONIC} --nodekey=${FILES[1]}"
CMD[2]="go run . --mnemonic=${MNEMONIC} --keyid=${FILES[2]}"

# Function to test MD5 checksums of output files
testMD5(){
    echo "Checking FILES MD5 checksum:"
    for i in $(seq 0 $((${#CMD[@]} - 1))); do
        eval "${CMD[$i]}"
        IN=$(md5sum ${FILES[$i]} | awk '{print $1}')
        OUT="${MD5[$i]}"

        if [ "$in" = "$out" ]; then
            echo "[PASSED]: File ${FILES[$i]} $IN"
        else
            echo "[FAILED]: File ${FILES[$i]} wrong md5 checksum. Want $OUT, got $IN"
            return 1
                
        fi
    done
    return 0
}

# Function to clean up output files
clean(){
    echo "Deleting files:"
    for f in ${FILES[@]}; do
        rm "$f" || (echo "Failed to delete: $f" && return 1)
        echo "File $f deleted"
    done
    return 0
}

# List of tests to be executed
TESTS[0]="testadr"
TESTS[1]="testMD5"
TESTS[2]="clean"

# Function to run all tests and handle errors
test() {
    ERRRS=""
    for test in "${TESTS[@]}"; do
        if ! $test; then
            ERRS[${#ERRS[@]}]+="failed"
            fi
        done
    if [[ ${#ERRS[@]} -gt 0 ]]; then
        exit 1
    fi
}

# Execute the tests
test