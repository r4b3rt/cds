# Example usage :
# Create the main Makefile in the root project directory.
# include Makefile.common
#=======================================================================================================================
# git info
VARS_OLD := $(.VARIABLES)
git_installed= $(shell if [ ` command -v git ` ];then echo 'yes'; fi)
ifeq "$(git_installed)" ""
  $(error Please install git before running `make`)
endif
GIT_BRANCH =$(shell git name-rev --name-only HEAD)
GIT_COMMIT =$(shell git rev-parse --short HEAD)
GIT_STATUS_HASH =$(shell git status -s -uno | sha256sum | awk '{ print $$1 }')
#GIT_STATUS =$(shell echo"$$( git status -s -uno) ")
$(shell echo"$$( git status -s -uno) ")
GIT_STATUS ?=no change
GIT_DIRTY =$(shell git describe --tags --dirty --always)
GIT_LAST_DATE=$(shell  echo $$(git log -1 --format=%cd))
#=======================================================================================================================
# go build info
go_installed= $(shell if [ ` command -v go ` ];then echo 'yes'; fi)
ifeq ($(go_installed),yes)
GOPATH 		?= $(shell go env GOPATH)
# Ensure GOPATH is set before running build process.
ifeq "$(GOPATH)" ""
  $(error Please set the environment variable GOPATH before running `make`)
endif
$(info ----  GOPROXY now is :$(GOPROXY) ---)

GO_VERSION 				=$(shell go version | sed 's|go version ||')
GO_VERSION_NUMBER 		?= $(word 3, $(GO_VERSION))
GO   					:= GO111MODULE=on go
GO_BUILD    			:= $(GO) build $(BUILD_FLAG) -tags codes
GO_TEST					:= $(GO) test -p $(P)
ROOT_URL				:=$(shell head -n 1 go.mod | sed  "s|module ||")
PACKAGE_LIST  			:= go list ./...| grep -vE "cmd"
PACKAGE_URIS  			:= $$($(PACKAGE_LIST))
PACKAGE_RELATIVE_PATHS 	:= $(PACKAGE_LIST) | sed 's|$(ROOT_URL)/||'
#GO_FILES     			:=$(shell echo $$(find $$($(PACKAGE_RELATIVE_PATHS)) -name "*.go"))
VERSION =$(shell cat VERSION)

ifdef version_go_file
GO_BUILD_VERSION_PKG := $(shell $(PACKAGE_LIST) | grep )
LD_FLAGS = -X '$(GO_BUILD_VERSION_PKG).Version=$(VERSION)'
LD_FLAGS += -X '$(GO_BUILD_VERSION_PKG).Branch=$(GIT_BRANCH)'
LD_FLAGS += -X '$(GO_BUILD_VERSION_PKG).Commit=$(GIT_COMMIT)'
LD_FLAGS += -X '$(GO_BUILD_VERSION_PKG).StatusHash=$(GIT_STATUS_HASH)'
LD_FLAGS += -X '$(GO_BUILD_VERSION_PKG).User=$(USER)'
LD_FLAGS += -X '$(GO_BUILD_VERSION_PKG).Time=$(DATE)'
LD_FLAGS += -X '$(GO_BUILD_VERSION_PKG).Status=$(GIT_STATUS)'
LD_FLAGS += -X '$(GO_BUILD_VERSION_PKG).GoVersion=$(GO_VERSION)'
endif

endif
#=======================================================================================================================
# env info
ARCH      := "`uname -s`"
DATE := $(shell date "+%Y-%m-%d %H:%M")
USER := $(shell id -u -n)

ifndef no_print_vars
$(foreach v,                                        \
  $(filter-out $(VARS_OLD) VARS_OLD,$(.VARIABLES)), \
  $(info $(v) = $($(v))))
endif
.PHONY : print_all
print_all:
	@echo GIT_BRANCH: $(GIT_BRANCH)
	@echo GIT_COMMIT: $(GIT_COMMIT)
	@echo GIT_STATUS_HASH: $(GIT_STATUS_HASH)
	@echo GIT_STATUS: $(GIT_STATUS)
	@echo GIT_DIRTY: $(GIT_DIRTY)
	@echo GIT_LAST_DATE: $(GIT_LAST_DATE)
	@if [ ` command -v go ` ];then \
	echo GOPATH: $(GOPATH); \
	echo GO_VERSION: $(GO_VERSION); \
	echo GO: $(GO); \
	echo GO_BUILD: $(GO_BUILD); \
	fi
	@echo VERSION: $(VERSION)
	@echo ARCH: $(ARCH)
	@echo DATE: $(DATE)
	@echo USER: $(USER)
	@if [ -n "$(version_go_file)" ]; then \
	echo GO_BUILD_VERSION_PKG: $(GO_BUILD_VERSION_PKG); \
	echo LD_FLAGS: $(LD_FLAGS); \
	fi



.PHONY: common-style
common-style:
	@echo ">> checking code style"
	@fmtRes=$$(gofmt -d $$(find . -path ./vendor -prune -o -name '*.go' -print)); \
	if [ -n "$${fmtRes}" ]; then \
		echo "gofmt checking failed!"; echo "$${fmtRes}"; echo; \
		exit 1; \
	fi
