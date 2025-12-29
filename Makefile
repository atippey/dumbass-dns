RELEASE_REPO := ghcr.io/$(shell git remote get-url origin | sed -e 's/.*:\(.*\).git/\1/g')
IMAGE_NAME := refresh
RELEASE_TAG := $(shell git describe --tags --exact-match HEAD 2>/dev/null || git branch --show-current)
PLATFORM := 'linux/arm64'

.PHONY: lint
lint:
	pylint src/dumbass_dns

.PHONY: docker
docker:
	docker build --platform $(PLATFORM) -t update:latest .

.PHONY: show-current-release-image
show-current-release-image:
	@echo $(RELEASE_REPO)/$(IMAGE_NAME):$(RELEASE_TAG)

PHONY: push
push: docker
	@source .env; \
		echo $$CR_PAT | docker login ghcr.io -u $$CR_USERNAME --password-stdin
	@docker tag update:latest $(RELEASE_REPO)/$(IMAGE_NAME):$(RELEASE_TAG)
	@docker push $(RELEASE_REPO)/$(IMAGE_NAME):$(RELEASE_TAG)

.PHONY: docker-secret
docker-secret:
	@source .env;
		kubectl create secret docker-registry ghcr-secret \
		--docker-server=ghcr.io \
		--docker-username=$$CR_USERNAME \
		--docker-password=$$CR_PAT \
		--docker-email=$$CR_EMAIL

.PHONY: aws-secret
aws-secret:
	@source .env; \
		TMP=$$(mktemp); \
		echo "{\
			"apiVersion": "v1",\
			"kind": "Secret",\
			"metadata": {\
				"name": "aws-credentials"\
			},\
			"type": "Opaque",\
			"data": {\
				"aws_access_key_id": "$$(printf $$AWS_ACCESS_KEY_ID | base64)",\
				"aws_secret_access_key": "$$(printf $$AWS_SECRET_ACCESS_KEY | base64)"\
			}\
		}" > $$TMP; \
		kubectl apply -f $$TMP ; \
		rm $$TMP

.PHONY: install
install:
	@helm upgrade --install dns chart/dumbass-dns -f ./values.yaml

.PHONY: run
run:
	@kubectl create job --from=cronjob/dns-dumbass-dns dns-dumbass-dns-manual-$$(date +%s) -n default
