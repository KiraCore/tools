module bip32cli

go 1.17

require (
	github.com/KiraCore/go-bip39 v1.1.0
	github.com/google/uuid v1.3.0
	github.com/spf13/cobra v1.4.0
)

require (
	github.com/inconshreveable/mousetrap v1.0.0 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
	golang.org/x/crypto v0.0.0-20220411220226-7b82a4e95df4 // indirect
)

replace github.com/KiraCore/go-bip39 v1.1.0 => ./bip39
