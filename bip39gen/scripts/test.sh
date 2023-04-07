#!/usr/bin/env bash
set -e
set -x
. /etc/profile

cd ./bip39gen || echo "Already in the root dir"

. ../bash-utils/bash-utils.sh

go test -v -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
go test -v -cover ./...

. ../bash-utils/bash-utils.sh

BIN_bip39gen="${GOBIN}/bip39gen"

ENTROPY="$(echo "daring collect artist first six arena brown design park syrup jump pluck" | sha256)"
MNEMONIC_TEST_1=$($BIN_bip39gen mnemonic -l 12 -e "$ENTROPY" --hex)
MNEMONIC_TEST_2=$($BIN_bip39gen mnemonic -l 12 -e "$ENTROPY" --hex)

[ "$MNEMONIC_TEST_1" == "$MNEMONIC_TEST_2" ] && \
 echoErr "ERROR: When user entropy is provided expected mnemonic to change every time, in the process of being mixed with computer provided entropy" && exit 1 || echoInfo "INFO: Test 1 passed"

# Test correctness of raw entropy to match results from https://iancoleman.io/bip39/
SEED_MNEMONIC="eagle gap major artwork napkin hover gate illness ball distance awful mountain salute guard scare edit scorpion praise trust potato cotton crazy unique result"
# 9fc82e0a6f3ed36b25a667e7426fec137820ad489cbfbf45f01bc932ce5c6837
ENTROPY_256="$(echo -n "$SEED_MNEMONIC" | tr '[:upper:]' '[:lower:]' | sha256)"
MNEMONIC_TEST_1=$(bip39gen mnemonic --length=24 --raw-entropy="$ENTROPY_256" --verbose=false --hex=true)
MNEMONIC_TEST_2="panther door little taxi unfold remain notable smooth trap beach wild cheap link find carbon obey satisfy convince alone mystery coconut comfort patch undo"

[ "$MNEMONIC_TEST_1" != "$MNEMONIC_TEST_2" ] && \
 echoErr "ERROR: When sha256 raw entropy is provided expected to end up with deterministic mnemonic, but results differ :(" && exit 1 || echoInfo "INFO: Test 2 passed"

set +x
runTest() {
  local test_cmd="$1"
  local test_name="$2"
  local test_out="$3"


  # Execute the test command and get the exit code
  RESULT=$(eval "$test_cmd")
  exit_code=$?

  # Get the command name
  # Check the exit code and print the result
  if [[ $exit_code -eq 0 ]]; then
    if [[ $RESULT == $test_out ]]; then
        echo "[PASS] $test_name"
    else
        bu echoError "[FAIL] $test_name"
    fi

  else
    bu echoError "[FAIL] $test_name"
  fi
}
#TestCase1(-l 12: default mnemonic lenght is 24 ):
RAW_ENT_BIN_WITHOUT_PREFIX="10011101001100000001011100000001101110100010010110110011001010101111000001101101011000010000110011000010100100011101110101001001"
RAW_ENT_HEX_WITHOUT_PREFIX="9d301701ba25b32af06d610cc291dd49"
RAW_ENT_HEX_WITHOUT_PREFIX_UPPER="9D301701BA25B32AF06D610CC291DD49"
RAW_ENT_BIN_WITH_PREFIX="0b10011101001100000001011100000001101110100010010110110011001010101111000001101101011000010000110011000010100100011101110101001001"
RAW_ENT_HEX_WITH_PREFIX="0x9d301701ba25b32af06d610cc291dd49"
RAW_ENT_HEX_WITH_PREFIX_UPPER="0x9D301701BA25B32AF06D610CC291DD49"
MNEMONIC_TEST_CASE_1="outdoor level scatter inmate forest nice script promote art behind jar nation"

runTest "$BIN_bip39gen mnemonic -l 12 --raw-entropy=$RAW_ENT_BIN_WITHOUT_PREFIX" "RAW: binary entropy without prefix" "$MNEMONIC_TEST_CASE_1"
runTest "$BIN_bip39gen mnemonic -l 12 --raw-entropy=$RAW_ENT_BIN_WITH_PREFIX" "RAW: binary entropy with prefix" "$MNEMONIC_TEST_CASE_1"
runTest "$BIN_bip39gen mnemonic -l 12 --raw-entropy=$RAW_ENT_HEX_WITHOUT_PREFIX --hex=true" "RAW: hex entropy without prefix, lower" "$MNEMONIC_TEST_CASE_1"
runTest "$BIN_bip39gen mnemonic -l 12 --raw-entropy=$RAW_ENT_HEX_WITHOUT_PREFIX_UPPER --hex=true" "RAW: hex entropy without prefix, upper" "$MNEMONIC_TEST_CASE_1"
runTest "$BIN_bip39gen mnemonic -l 12 --raw-entropy=$RAW_ENT_HEX_WITH_PREFIX --hex=true" "RAW: hex entropy with prefix, lower" "$MNEMONIC_TEST_CASE_1"
runTest "$BIN_bip39gen mnemonic -l 12 --raw-entropy=$RAW_ENT_HEX_WITH_PREFIX_UPPER --hex=true" "RAW: hex entropy with prefix, upper" "$MNEMONIC_TEST_CASE_1"

#TestCase2(24 words + prefix check. Hash starts from 0x):
RAW_ENT_BIN_WITHOUT_PREFIX="0000101111011000111111101110000110001100100100001011011011011101010111000111101000001011101111111011000011011111011011110101111000011001100110010011011110010101111100100110000000011101011001101100001000111101101001000010001000110111010101010000111111000010"
RAW_ENT_HEX_WITHOUT_PREFIX="0bd8fee18c90b6dd5c7a0bbfb0df6f5e19993795f2601d66c23da42237550fc2"
RAW_ENT_HEX_WITHOUT_PREFIX_UPPER="0BD8FEE18C90B6DD5C7A0BBFB0DF6F5E19993795F2601D66C23DA42237550FC2"
RAW_ENT_BIN_WITH_PREFIX="0b0000101111011000111111101110000110001100100100001011011011011101010111000111101000001011101111111011000011011111011011110101111000011001100110010011011110010101111100100110000000011101011001101100001000111101101001000010001000110111010101010000111111000010"
RAW_ENT_HEX_WITH_PREFIX="0x0bd8fee18c90b6dd5c7a0bbfb0df6f5e19993795f2601d66c23da42237550fc2"
RAW_ENT_HEX_WITH_PREFIX_UPPER="0x0BD8FEE18C90B6DD5C7A0BBFB0DF6F5E19993795F2601D66C23DA42237550FC2"
MNEMONIC_TEST_CASE_2="armed side reveal bomb arena huge impose door sausage manage swift rotate office orange fit equal buddy current month embark casino pride disease firm"

runTest "$BIN_bip39gen mnemonic --raw-entropy=$RAW_ENT_BIN_WITHOUT_PREFIX" "RAW: binary entropy without prefix" "$MNEMONIC_TEST_CASE_2"
runTest "$BIN_bip39gen mnemonic --raw-entropy=$RAW_ENT_BIN_WITH_PREFIX" "RAW: binary entropy with prefix" "$MNEMONIC_TEST_CASE_2"
runTest "$BIN_bip39gen mnemonic --raw-entropy=$RAW_ENT_HEX_WITHOUT_PREFIX --hex=true" "RAW: hex entropy without prefix, lower" "$MNEMONIC_TEST_CASE_2"
runTest "$BIN_bip39gen mnemonic --raw-entropy=$RAW_ENT_HEX_WITHOUT_PREFIX_UPPER --hex=true" "RAW: hex entropy without prefix, upper" "$MNEMONIC_TEST_CASE_2"
runTest "$BIN_bip39gen mnemonic --raw-entropy=$RAW_ENT_HEX_WITH_PREFIX --hex=true" "RAW: hex entropy with prefix, lower" "$MNEMONIC_TEST_CASE_2"
runTest "$BIN_bip39gen mnemonic --raw-entropy=$RAW_ENT_HEX_WITH_PREFIX_UPPER --hex=true" "RAW: hex entropy with prefix, upper" "$MNEMONIC_TEST_CASE_2"

#TestCase3(Cipher: SHA256)
MNEMONIC_TEST_CASE_3="volcano uncle castle avocado hole wear embark steak upper afraid era donor result member host dream end enemy switch marble exit hungry donate setup"
runTest "$BIN_bip39gen mnemonic --entropy="Hello, Kira!" --cipher=sha256" "CIPHER[SHA256]: Test" "MNEMONIC_TEST_CASE_3"

#TestCase4(Cipher: SHA512)
MNEMONIC_TEST_CASE_4="dress depth dolphin math attract hole ribbon vague text popular tool hood source puppy reason feature birth display upgrade snow stand play chief rubber isolate woman deposit hip okay plug silver clock buzz help future artist neck spend walk century snack word clip dynamic enforce eight ski canal"
runTest "$BIN_bip39gen mnemonic --entropy="Hello, Kira!" --cipher=sha512" "CIPHER[SHA512]: Test" "MNEMONIC_TEST_CASE_4"

#TestCase6(Cipher: padding)
MNEMONIC_TEST_CASE_5="outdoor level scale abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon antique"
runTest "$BIN_bip39gen mnemonic -l 12 --entropy=100111010011000000010111 --cipher=padding" "CIPHER[padding]: Test" "MNEMONIC_TEST_CASE_5"