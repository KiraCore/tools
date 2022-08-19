.PHONY: test build publish

test:
	./bip39/scripts/test.sh
	./bip39/scripts/build.sh
	./scripts/build.sh
	./scripts/test.sh

build:
	./scripts/build.sh
	./scripts/build.sh

publish:
	./scripts/publish.sh