.PHONY: clean local test linux macos mocks docker push scm-source.json e2e

#kswj - temp to build locally
#GO_BINARY ?= /home/jenkins/go/bin/go1.17.6
GO_BINARY ?= /usr/local/go/bin/go
BINARY ?= postgres-operator
BUILD_FLAGS ?= -v
CGO_ENABLED ?= 0
ifeq ($(RACE),1)
	BUILD_FLAGS += -race -a
    CGO_ENABLED=1
endif

LOCAL_BUILD_FLAGS ?= $(BUILD_FLAGS)
LDFLAGS ?= -X=main.version=$(VERSION)
DOCKERDIR = docker

IMAGE ?= $(BINARY)
TAG ?= $(VERSION)
GITHEAD = $(shell git rev-parse --short HEAD)
GITURL = $(shell git config --get remote.origin.url)
GITSTATUS = $(shell git status --porcelain || echo "no changes")
SOURCES = cmd/main.go
VERSION ?= $(shell git describe --tags --always --dirty)
DIRS := cmd pkg
PKG := `$(GO_BINARY) list ./... | grep -v /vendor/`

ifeq ($(DEBUG),1)
	DOCKERFILE = DebugDockerfile
	DEBUG_POSTFIX := -debug-$(shell date hhmmss)
	BUILD_FLAGS += -gcflags "-N -l"
else
	DOCKERFILE = Dockerfile
endif

ifeq ($(FRESH),1)
  DEBUG_FRESH=$(shell date +"%H-%M-%S")
endif

ifdef CDP_PULL_REQUEST_NUMBER
	CDP_TAG := -${CDP_BUILD_VERSION}
endif

ifndef GOPATH
	GOPATH := $(HOME)/go
endif

PATH := $(GOPATH)/bin:$(PATH)
SHELL := env PATH=$(PATH) $(SHELL)

default: local

clean:
	rm -rf build scm-source.json

local: ${SOURCES}
	hack/verify-codegen.sh
	CGO_ENABLED=${CGO_ENABLED} $(GO_BINARY) build -o build/${BINARY} $(LOCAL_BUILD_FLAGS) -ldflags "$(LDFLAGS)" $^

linux: ${SOURCES}
	GOOS=linux GOARCH=amd64 CGO_ENABLED=${CGO_ENABLED} $(GO_BINARY) build -o build/linux/${BINARY} ${BUILD_FLAGS} -ldflags "$(LDFLAGS)" $^

macos: ${SOURCES}
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=${CGO_ENABLED} $(GO_BINARY) build -o build/macos/${BINARY} ${BUILD_FLAGS} -ldflags "$(LDFLAGS)" $^

docker-context: scm-source.json linux
	mkdir -p docker/build/
	cp build/linux/${BINARY} scm-source.json docker/build/

docker: ${DOCKERDIR}/${DOCKERFILE} docker-context
	echo `(env)`
	echo "Tag ${TAG}"
	echo "Version ${VERSION}"
	echo "CDP tag ${CDP_TAG}"
	echo "git describe $(shell git describe --tags --always --dirty)"
	cd "${DOCKERDIR}" && docker build --rm -t "$(IMAGE):$(TAG)$(CDP_TAG)$(DEBUG_FRESH)$(DEBUG_POSTFIX)" -f "${DOCKERFILE}" .

indocker-race:
# kswj changed from 1.17.3 to 1.18
	docker run --rm -v "${GOPATH}":"${GOPATH}" -e GOPATH="${GOPATH}" -e RACE=1 -w ${PWD} golang:1.17.3 bash -c "make linux"
#	docker run --rm -v "${GOPATH}":"${GOPATH}" -e GOPATH="${GOPATH}" -e RACE=1 -w ${PWD} golang:1.19 bash -c "make linux"

push:
	docker push "$(IMAGE):$(TAG)$(CDP_TAG)"

scm-source.json: .git
	echo '{\n "url": "git:$(GITURL)",\n "revision": "$(GITHEAD)",\n "author": "$(USER)",\n "status": "$(GITSTATUS)"\n}' > scm-source.json

mocks:
	GO111MODULE=on go generate ./...

tools:
#kswj - temp to build locally - pkg/cluster/k8sres.go:596:15: undefined: "k8s.io/api/core/v1".LifecycleHandler
#	GO111MODULE=on go get -d k8s.io/client-go@kubernetes-1.22.4
# current cray
#	GO111MODULE=on go get k8s.io/client-go@kubernetes-1.16.3
	GO111MODULE=on go get -d k8s.io/client-go@kubernetes-1.22.4
	GO111MODULE=on go install github.com/golang/mock/mockgen@v1.6.0
#	GO111MODULE=on go get github.com/googleapis/gnostic@none

	GO111MODULE=on go mod tidy

fmt:
	@gofmt -l -w -s $(DIRS)

vet:
	@$(GO_BINARY) vet $(PKG)
	@staticcheck $(PKG)

deps: tools
	GO111MODULE=on $(GO_BINARY) mod vendor

test:
	hack/verify-codegen.sh
	GO111MODULE=on $(GO_BINARY) test ./...

codegen:
	hack/update-codegen.sh

e2e: docker # build operator image to be tested
	cd e2e; make e2etest
