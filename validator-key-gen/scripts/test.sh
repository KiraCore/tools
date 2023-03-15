#!/usr/bin/env bash

# Set mnemonic variable
mnemonic="\"over where supreme taste warrior morning perfect memory glove stereo taste trip sheriff fringe weather finger segment under arrange gain warrior olympic urge vacant\""

# Testing address generation with predetermined mnemonic against hard coded results
Output=("kira103luqf09g5juctmvrmgnw5gmn2mhpelqhcsy84" "kiravaloper103luqf09g5juctmvrmgnw5gmn2mhpelqy7v8le" "kiravalcons103luqf09g5juctmvrmgnw5gmn2mhpelqsdlmnc")
AdrType=("Account address" "Validator address" "Consensus address")
Input=("go run . --mnemonic=${mnemonic} --accadr" "go run . --mnemonic=${mnemonic} --valadr" "go run . --mnemonic=${mnemonic} --consadr")

testadr(){
    echo "Testing address formation:"
    for i in $(seq 0 $((${#Input[@]} - 1))); do
        in=$(eval "${Input[$i]}")
        out="${Output[$i]}"
        adr="${AdrType[$i]}"
        
        if [ "$in" = "$out" ]; then
                echo "[PASSED]: $adr"
            else
                echo "[FAILED]: malformed $adr. Want $out, got $in"
                return 1
        fi
    done
    return 0
}

# Checking md5 checksum of created files against hard coded results
md5=("8a100779d27e5ae2098498674df32f8b" "d14df3851190d360953989e296db3cf3" "7ab595fe3d53672ac918a351bcaa10b5")
files=("./valkey" "./nodekey" "./keyid")
cmd=("go run . --mnemonic=${mnemonic} --valkey=${files[0]}" "go run . --mnemonic=${mnemonic} --nodekey=${files[1]}" "go run . --mnemonic=${mnemonic} --keyid=${files[2]}")

testmd5(){
    echo "Checking files md5 checksum:"
    for i in $(seq 0 $((${#cmd[@]} - 1))); do
        eval "${cmd[$i]}"
        in=$(md5sum ${files[$i]} | awk '{print $1}')
        out="${md5[$i]}"

        if [ "$in" = "$out" ]; then
            echo "[PASSED]: File ${files[$i]} $in"
        else
            echo "[FAILED]: File ${files[$i]} wrong MD5. Want $out, got $in"
            return 1
                
        fi
    done
    return 0
}

# Deleting files created by testmd5 function
clean(){
    echo "Deleting files:"
    for f in ${files[@]}; do 
        rm "$f" ||  (echo "Failed to delete: $f" &&  return 1)
        echo "File $f deleted"
    done
    return 0
}

tests=(testadr testmd5 clean)

test() {
    errs=()
    for test in "${tests[@]}"; do
        if ! $test; then
            errs+=("failed")
        fi
    done
    if [[ ${#errs[@]} -gt 0 ]]; then
        exit 1
    fi
}






