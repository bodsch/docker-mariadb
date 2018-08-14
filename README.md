# docker-mariadb

Alpine based docker container with an MariaDB.

The container stores there data at the hostsystem in the directory `/tmp/docker-data/mariadb` or in a configured data directory.

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-mariadb.svg?branch)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-mariadb.svg?branch)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-mariadb.svg?branch)][travis]

[hub]: https://hub.docker.com/r/bodsch/docker-mariadb/
[microbadger]: https://microbadger.com/images/bodsch/docker-mariadb
[travis]: https://travis-ci.org/bodsch/docker-mariadb


# Build

Your can use the included Makefile.

To build the Container: `make build`

Starts the Container: `make run`

Starts the Container with Login Shell: `make shell`

Entering the Container: `make exec`

Stop (but **not kill**): `make stop`

History `make history`


# Docker Hub

You can find the Container also at  [DockerHub](https://hub.docker.com/r/bodsch/docker-mariadb/)


# Versions

 - mariadb 10.2.x


# Supported Environmentvars

 - `MARIADB_ROOT_PASSWORD` (default: randomized generated with `$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)`)
 - `MARIADB_SYSTEM_USER`   (default: generated with `$(grep user /etc/mysql/my.cnf | cut -d '=' -f 2 | sed 's| ||g')`)


# Ports

 - 3306
