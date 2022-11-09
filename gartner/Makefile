ACADIA_TERRAFORM_ARTIFACT_URL := wcp-acadia-team-docker-local.artifactory.swg-devops.com
TAG := 2.0.0
container-name := "acadia-terraform"
targets:
	docker build  -t  $(ACADIA_TERRAFORM_ARTIFACT_URL)/$(container-name):$(TAG) .
	docker push $(ACADIA_TERRAFORM_ARTIFACT_URL)/$(container-name):$(TAG)

