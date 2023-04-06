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

runTest() {
  local test_cmd="$1"
  local test_name="$2"


  # Execute the test command and get the exit code
  eval "$test_cmd &> /dev/null ||:"
  exit_code=$?

  # Get the command name
  # Check the exit code and print the result
  if [ $exit_code -eq 0 ]; then
    echo "[PASS] $test_name"
  else
    bu echoError "[FAIL] $test_name"
  fi
}




