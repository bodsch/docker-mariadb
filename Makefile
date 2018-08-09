
include env_make

NS = bodsch

REPO = docker-mariadb
NAME = mariadb
INSTANCE = default

BUILD_DATE := $(shell date +%Y-%m-%d)
BUILD_VERSION := $(shell date +%y%m)
MARIADB_VERSION ?= $(shell curl \
  --silent \
  --location \
  --retry 3 \
  http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/APKINDEX.tar.gz | \
  gunzip | \
  strings | \
  grep -A1 "P:mariadb-common" | \
  tail -n1 | \
  cut -d ':' -f2 | \
  cut -d '-' -f1)

.PHONY: build push shell run start stop rm release

default: build

params:
	@echo ""
	@echo " MARIADB_VERSION: $(MARIADB_VERSION)"
	@echo " BUILD_DATE     : $(BUILD_DATE)"
	@echo ""

build: params
	docker build \
		--force-rm \
		--compress \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg MARIADB_VERSION=$(MARIADB_VERSION) \
		--tag $(NS)/$(REPO):${MARIADB_VERSION} .

clean:
	docker rmi \
		$(NS)/$(REPO):${MARIADB_VERSION}

history:
	docker history \
		$(NS)/$(REPO):${MARIADB_VERSION}

push:
	docker push \
		$(NS)/$(REPO):${MARIADB_VERSION}

shell:
	docker run \
		--rm \
		--name $(NAME)-$(INSTANCE) \
		--interactive \
		--tty \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):${MARIADB_VERSION} \
		/bin/sh

run:
	docker run \
		--rm \
		--name $(NAME)-$(INSTANCE) \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):${MARIADB_VERSION}

exec:
	docker exec \
		--interactive \
		--tty \
		$(NAME)-$(INSTANCE) \
		/bin/sh

start:
	docker run \
		--detach \
		--name $(NAME)-$(INSTANCE) \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):${MARIADB_VERSION}

stop:
	docker stop \
		$(NAME)-$(INSTANCE)

rm:
	docker rm \
		$(NAME)-$(INSTANCE)

release:
	make push -e VERSION=${MARIADB_VERSION}

default: build


