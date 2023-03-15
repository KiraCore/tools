#!/usr/bin/env bash

mnemonic='"over where supreme taste warrior morning perfect memory glove stereo taste trip sheriff fringe weather finger segment under arrange gain warrior olympic urge vacant"'


# Testing address generation with predetermined mnemonic against hard coded results
Output[0]="kira103luqf09g5juctmvrmgnw5gmn2mhpelqhcsy84"         #accadr
Output[1]="kiravaloper103luqf09g5juctmvrmgnw5gmn2mhpelqy7v8le"  #valadr
Output[2]="kiravalcons103luqf09g5juctmvrmgnw5gmn2mhpelqsdlmnc"   #consadr

AdrType[0]="Account address" 
AdrType[1]="Validator address" 
AdrType[2]="Consensus address"

Input[0]="go run . --mnemonic=${mnemonic} --accadr" 
Input[1]="go run . --mnemonic=${mnemonic} --valadr" 
Input[2]="go run . --mnemonic=${mnemonic} --consadr"


testadr(){
    echo "Testing address formation:"
    for (( i = 0; i < ${#Input[@]} ; i++ ));
    do
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
md5[0]="8a100779d27e5ae2098498674df32f8b" # valkey 
md5[1]="d14df3851190d360953989e296db3cf3" # nodekey
md5[2]="7ab595fe3d53672ac918a351bcaa10b5"  # keyid

files[0]="./valkey" 
files[1]="./nodekey" 
files[2]="./keyid"

cmd[0]="go run . --mnemonic=${mnemonic} --valkey=${files[0]}" 
cmd[1]="go run . --mnemonic=${mnemonic} --nodekey=${files[1]}" 
cmd[2]="go run . --mnemonic=${mnemonic} --keyid=${files[2]}"

testmd5(){
    echo "Checking files md5 checksum:"
    for (( i = 0; i < ${#cmd[@]} ; i++ ));
        do
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

# Deleating files created by testmd5 func
clean(){
    echo "Deleting files:"
    for f in ${files[@]};
        do 
            rm "$f" ||  (echo "Failed to delete: $f" &&  return 1)
            echo "File $f deleted"
        done
    return 0
}

# Launch sequence of tests

declare -a tests=(testadr testmd5 clean)

test(){
    errs=()
    for test in "${tests[@]}"; do
        $test >&2
        if [[ $? -eq 1 ]]; then
            errs+=("failed")
        fi
    done
    if [[ ${#errs[@]}>0 ]]; then
        exit 1
    fi

}