APP?=blog
RELEASE?=0.0.1
CONTAINER_IMAGE?=docker.io/stamm/${APP}
BUILDKIT?=1
export DOCKER_BUILDKIT = $(BUILDKIT)

.PHONY: container
container:
	docker build --build-arg release=$(RELEASE) -t $(CONTAINER_IMAGE):$(RELEASE) .

.PHONY: push
push: container
	docker push $(CONTAINER_IMAGE):$(RELEASE)

.PHONY: deploy
deploy:
	helm upgrade blog ./deploy/k8s/blog/ --install --namespace=blog -f ./deploy/k8s/blog/values-live.yaml --debug --set image.tag=${RELEASE}
