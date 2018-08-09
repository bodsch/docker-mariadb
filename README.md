# docker-myariadb

Docker container with an running MariaDB Database.

The Container stores there Data at the Hostsystem in the Directory `/tmp/docker-data/myariadb` or in a configured Datadirectory.

# Status

[![Docker Pulls](https://img.shields.io/docker/pulls/bodsch/docker-myariadb.svg?branch)][hub]
[![Image Size](https://images.microbadger.com/badges/image/bodsch/docker-myariadb.svg?branch)][microbadger]
[![Build Status](https://travis-ci.org/bodsch/docker-myariadb.svg?branch)][travis]

[hub]: https://hub.docker.com/r/bodsch/docker-myariadb/
[microbadger]: https://microbadger.com/images/bodsch/docker-myariadb
[travis]: https://travis-ci.org/bodsch/docker-myariadb


# Build

Your can use the included Makefile.

To build the Container: `make build`

Starts the Container: `make run`

Starts the Container with Login Shell: `make shell`

Entering the Container: `make exec`

Stop (but **not kill**): `make stop`

History `make history`


# Docker Hub

You can find the Container also at  [DockerHub](https://hub.docker.com/r/bodsch/docker-myariadb/)


# Versions

 - mariadb 10.1.x


# Supported Environmentvars

 - `MARIADB_ROOT_PASSWORD` (default: generated with `$(pwgen -s 15 1)`)
 - `MARIADB_SYSTEM_USER`   (default: generated with `$(grep user /etc/mysql/my.cnf | cut -d '=' -f 2 | sed 's| ||g')`)


# Ports

 - 3306
