.PHONY: help build release test clean

VERSION ?= 0.1.0

help:
	@echo "Targets:"
	@echo "  make build    - Debug build"
	@echo "  make release  - Release build (stripped)"
	@echo "  make test     - Run tests"
	@echo "  make clean    - Clean build artifacts"

build:
	go build -o tunnel-watch .

release:
	go build -ldflags "-s -w -X main.version=$(VERSION)" -o tunnel-watch .

test:
	go test ./...

clean:
	rm -f tunnel-watch
	rm -rf dist
