.PHONY: lint
lint:
	pylint src/dumbass_dns

.PHONY: docker
docker:
	docker build .