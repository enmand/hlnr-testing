NAME?="hlnr-test"

VCS_BRANCH?=$(shell git branch | grep \* | cut -f2 -d' ')
VCS_SHA?=$(shell git rev-parse --verify HEAD)
BUILD_DATE?=$(shell git show -s --date=iso8601-strict --pretty=format:%cd $$VCS_SHA)

RELEASE_VERSION?=$(shell git describe --always --tags --dirty | sed 's/^v//')
ifdef TRAVIS_TAG
	RELEASE_VERSION=$(shell echo $(TRAVIS_TAG) | sed 's/^v//')
endif

RELEASE_NAME?=$(NAME)
ifdef TRAVIS_PULL_REQUEST_BRANCH
	RELEASE_VERSION=$(TRAVIS_PULL_REQUEST_SHA)
	RELEASE_NAME="$(NAME)-$(shell echo $(TRAVIS_PULL_REQUEST_BRANCH) | sed "s/[^[:alnum:].-]/-/g")"
	# Override VCS_BRANCH on travis becuase it uses the FETCH_HEAD
	VCS_BRANCH=$(TRAVIS_PULL_REQUEST_BRANCH)
endif

all:

docker:
	docker build -t enmand/$(NAME) \
		--label "org.label-schema.build-date"="$(BUILD_DATE)" \
		--label "org.label-schema.name"="$(RELEASE_NAME)" \
		--label "org.label-schema.vcs-ref"="$(VCS_SHA)" \
		--label "org.label-schema.vendor"="Arigato Machine Inc." \
		--label "org.label-schema.version"="$(RELEASE_VERSION)" \
		--label "org.vcs-branch"="$(VCS_BRANCH)" \
		.

release: release-docker

release-docker: docker-login docker
	docker tag arigato/$(NAME) arigato/$(NAME):$(RELEASE_VERSION)
	docker push arigato/$(NAME):latest
	docker push arigato/$(NAME):$(RELEASE_VERSION)

docker-login:
	docker login -u="$$DOCKER_USERNAME" -p="$$DOCKER_PASSWORD"