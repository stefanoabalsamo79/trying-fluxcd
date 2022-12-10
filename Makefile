YQ:=$(shell which yq)
KUBECTL:=$(shell which kubectl)
DOCKER:=$(shell which docker)
KIND:=$(shell which kind)
INFO_FILE:="./info.yaml"
CLUSTER_NAME:=$(shell ${YQ} e '.clusterName' ${INFO_FILE})
DEFAULT_CLUSTER_NAME:=$(shell ${YQ} e '.defaultClusterName' ${INFO_FILE})
NAMESPACE:=$(shell ${YQ} e '.app.namespace' ${INFO_FILE})

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
	@echo "CLUSTER_NAME: [$(CLUSTER_NAME)]"

cluster_start:
	$(KIND) create cluster

cluster_delete:
	$(KIND) delete cluster --name $(CLUSTER_NAME)
	$(KIND) delete cluster --name $(DEFAULT_CLUSTER_NAME)

create_cluster:
	$(KIND) create \
	cluster --config=infra/cluster.yaml \
	--name $(CLUSTER_NAME)

set_context_cluster:
	$(KUBECTL) config set-context $(CLUSTER_NAME)

cluster_info:
	$(KUBECTL) cluster-info --context kind-$(CLUSTER_NAME)

ingress_controller_install:
	$(KUBECTL) apply -f infra/ingress_controller.yaml
	@sleep 30
	$(MAKE) wait_for_ingress_controller
  
wait_for_ingress_controller:
	$(KUBECTL) wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

create_namespace:
	$(KUBECTL) create -f infra/namespace.yaml

delete_namespace:
	$(KUBECTL) delete -f infra/namespace.yaml

app_build_tag_push_image_apply:
	$(MAKE) -C ./app build tag load_image apply

all:
	$(MAKE) print_mk_var \
	cluster_start \
	create_cluster \
	set_context_cluster \
	cluster_info \
	ingress_controller_install \
	wait_for_ingress_controller \
	create_namespace \
	app_build_tag_push_image_apply

clean_up: cluster_delete
