.PHONY: clean clean-mocks testpop lint mocks out setup test test-integration test-unit test-race

SHELL = /bin/bash

export GO15VENDOREXPERIMENT=1
NOVENDOR = $(shell GO15VENDOREXPERIMENT=1 glide novendor)

export PATH := $(shell pwd)/scripts/travis/thrift-release/linux-x86_64:$(PATH)
export PATH := $(shell pwd)/scripts/travis/thrift-gen-release/linux-x86_64:$(PATH)
export PATH := $(GOPATH)/bin:$(PATH)


# Automatically gather packages
PKGS = $(shell find . -type d -maxdepth 3 \
	! -path '*/.git*' \
	! -path '*/_*' \
	! -path '*/vendor*' \
	! -path '*/test*' \
	! -path '*/gen-go*' \
)

out:	test

clean:
	rm -f testpop

clean-mocks:
	rm -f test/mocks/*.go forward/mock_*.go
	rm -rf test/thrift/pingpong/

lint:
	@:>lint.log

	@-golint ./... | grep -Ev '(^vendor|test|gen-go)/' | tee -a lint.log

	@for pkg in $(PKGS); do \
		scripts/lint/run-vet "$$pkg" | tee -a lint.log; \
	done;

	@[ ! -s lint.log ]
	@rm -f lint.log

mocks:
	test/gen-testfiles

dev_deps:
	go get github.com/uber/tchannel-go/thrift/thrift-gen
	go get github.com/golang/lint/golint
	./scripts/go-get-version.sh github.com/vektra/mockery/.../@130a05e

setup: dev_deps
	glide install --cache
	@if ! which thrift | grep -q /; then \
		echo "thrift not in PATH. (brew install thrift?)" >&2; \
 		exit 1; \
	fi

	ln -sf ../../scripts/pre-commit .git/hooks/pre-commit

test:	test-unit test-integration

test-integration:
	test/run-integration-tests

test-unit:
	go generate $(NOVENDOR)
	test/go-test-prettify $(NOVENDOR)

test-race:
	go generate $(NOVENDOR)
	test/go-test-prettify -race $(NOVENDOR)

testpop:	clean
	go build ./scripts/testpop/
