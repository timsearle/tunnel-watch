.PHONY: help build release test clean

help:
	@echo "Targets:"
	@echo "  make build    - Debug build"
	@echo "  make release  - Release build"
	@echo "  make test     - Run tests"
	@echo "  make clean    - Clean build artifacts"

build:
	swift build

release:
	swift build -c release

test:
	swift test

clean:
	swift package clean
