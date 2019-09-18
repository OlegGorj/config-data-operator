
APP?=config-data-operator
APIVER?=v2
RELEASE?=1.0
IMAGE?=${REGISTRY}/${APP}:${RELEASE}
DOCKER_ORG?=oleggorj

PORT?=8000
LB_EXTERNAL_PORT?=8000

ENV?=SANDBOX

K8S_CHART?=service-config
K8S_NAMESPACE?=default
NODESELECTOR?=services

clean:
		docker stop ${APP} || true && docker rm ${APP} || true

build: clean
		operator-sdk build oleggorj/config-data-operator

run: push
		docker run --name ${APP} oleggorj/config-data-operator

push: build
		docker push oleggorj/config-data-operator

deployclean:
	kubectl delete -f ./deploy/crds/cloudnative_v1alpha1_repository_cr.yaml -n ${K8S_NAMESPACE}
	kubectl delete -f ./deploy/operator.yaml

deploy: push
		kubectl apply -f deploy/crds/cloudnative_v1alpha1_repository_crd.yaml
		kubectl apply -f deploy/role.yaml
		kubectl apply -f deploy/service_account.yaml
		kubectl apply -f deploy/role_binding.yaml
		kubectl apply -f ./deploy/operator.yaml
		kubectl apply -f ./deploy/crds/cloudnative_v1alpha1_repository_cr.yaml -n ${K8S_NAMESPACE}
