#
# This script is used to build and test single version of docker image.
#
# Name of resulting image will be: `NAMESPACE/IMAGE_NAME:VERSION-OS`.
#
# IMAGE_NAME  name of image, usually name of the main component within container
# NAMESPACE  namespace of image, defaults to ravensys
# OS  distribution to build upon (currently supported only `centos7`)
# VERSION  image version, must match with subdirectory name in repo
# UPDATE_BASE  if set to true, base image is updated on build
#

DOCKER = @docker

ifeq ($(UPDATE_BASE),true)
	BUILD_OPTIONS += --pull=true
endif

.PHONY: all
all: test
	$(DOCKER) tag "$(NAMESPACE)/$(IMAGE_NAME)-candidate:$(VERSION)-$(OS)" "$(NAMESPACE)/$(IMAGE_NAME):$(VERSION)-$(OS)"

.PHONY: build
build:
	$(DOCKER) build $(BUILD_OPTIONS) -t "$(NAMESPACE)/$(IMAGE_NAME):$(VERSION)-$(OS)" -f "$(VERSION)/Dockerfile.$(OS)" .

.PHONY: test
test: IMAGE_NAME := $(IMAGE_NAME)-candidate
test: build
	IMAGE_NAME="$(NAMESPACE)/$(IMAGE_NAME):$(VERSION)-$(OS)" test/run
	$(DOCKER) tag "$(NAMESPACE)/$(IMAGE_NAME):$(VERSION)-$(OS)" "$(NAMESPACE)/$(subst -candidate,,$(IMAGE_NAME)):$(VERSION)-$(OS)"

.PHONY: clean
clean:
	-$(DOCKER) rmi "$(NAMESPACE)/$(IMAGE_NAME)-candidate:$(VERSION)-$(OS)"

.PHONY: cleanall
cleanall: clean
	-$(DOCKER) rmi "$(NAMESPACE)/$(IMAGE_NAME):$(VERSION)-$(OS)"
