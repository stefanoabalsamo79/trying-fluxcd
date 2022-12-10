YQ:=$(shell which yq)
JQ:=$(shell which jq)
KUBECTL:=$(shell which kubectl)
DOCKER:=$(shell which docker)
KIND:=$(shell which kind)
KUSTOMIZE:=$(shell which kustomize)

DEPLOY_PATH:="./kustomize"
INFO_FILE:="../info.yaml"
DEMO_REPOSITORY:=$(shell ${YQ} e '.demoRepository' ${INFO_FILE})
APP_NAME:=$(shell ${YQ} e '.app.name' ${INFO_FILE})
VERSION:=$(shell ${YQ} e '.app.version' ${INFO_FILE})
NAMESPACE:=$(shell ${YQ} e '.app.namespace' ${INFO_FILE})
IMAGE_NAME_TAG:=$(APP_NAME):$(VERSION)
FULLY_QUALIFIED_IMAGE_URL:=$(ARTIFACT_REGISTRY)$(IMAGE_NAME_TAG)
CLUSTER_NAME:=$(shell ${YQ} e '.clusterName' ${INFO_FILE})

# params-guard-%:
# 	@if [ "${${*}}" = "" ]; then \
# 			echo "[$*] not set"; \
# 			exit 1; \
# 	fi

# check_compulsory_params: params-guard-LAB

print_mk_var:
	@echo "YQ: [$(YQ)]"
	@echo "KUBECTL: [$(KUBECTL)]"
	@echo "DOCKER: [$(DOCKER)]"
	@echo "KIND: [$(KIND)]"
	@echo "INFO_FILE: [$(INFO_FILE)]"
	@echo "DEMO_REPOSITORY: [$(DEMO_REPOSITORY)]"
	@echo "APP_NAME: [$(APP_NAME)]"
	@echo "VERSION: [$(VERSION)]"
	@echo "IMAGE_NAME_TAG: [$(IMAGE_NAME_TAG)]"
	@echo "FULLY_QUALIFIED_IMAGE_URL: [$(FULLY_QUALIFIED_IMAGE_URL)]"

build:
	$(DOCKER) build \
	-t $(IMAGE_NAME_TAG) \
	--pull \
	--no-cache \
	-f ./src/Dockerfile \
	./src

tag: 
	$(DOCKER) tag \
	$(IMAGE_NAME_TAG) \
	$(FULLY_QUALIFIED_IMAGE_URL)

load_image: 
	$(KIND) load \
	docker-image $(FULLY_QUALIFIED_IMAGE_URL) \
	--name $(CLUSTER_NAME)

apply:
	$(KUSTOMIZE) \
	build $(DEPLOY_PATH) | \
	$(KUBECTL) apply \
	-n $(NAMESPACE) \
	-f -



