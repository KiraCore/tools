.PHONY: install start build publish

install: go.sum
		go install .

start:
	go run main.go

build:
	./scripts/build.sh

publish:
	./scripts/publish.sh