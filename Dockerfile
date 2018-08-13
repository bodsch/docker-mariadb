
FROM alpine:3.8

ARG BUILD_DATE
ARG BUILD_VERSION
ARG MARIADB_VERSION

EXPOSE 3306

RUN \
  apk update --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add --quiet --no-cache \
    curl \
    jq \
    util-linux \
    mariadb \
    mariadb-client \
    pwgen && \
  mkdir /etc/mysql/conf.d && \
  cp /etc/mysql/my.cnf /etc/mysql/my.cnf-DIST && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

COPY rootfs/ /

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD /init/health_check.sh

VOLUME [ "/etc/mysql/conf.d" ]

CMD [ "/init/run.sh" ]

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@boone-schulz.de>" \
  org.label-schema.build-date=${BUILD_DATE} \
  org.label-schema.name="MariaDB Docker Image" \
  org.label-schema.description="Inofficial MariaDB Docker Image" \
  org.label-schema.url="https://www.mariadb.com" \
  org.label-schema.vcs-url="https://github.com/bodsch/docker-mariadb" \
  org.label-schema.vendor="Bodo Schulz" \
  org.label-schema.version=${MARIADB_VERSION} \
  org.label-schema.schema-version="1.0" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license="unlicense"

# ---------------------------------------------------------------------------------------
