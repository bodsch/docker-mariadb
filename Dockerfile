
FROM alpine:3.8

ARG VCS_REF
ARG BUILD_DATE
ARG BUILD_VERSION
ARG MARIADB_VERSION

# ---------------------------------------------------------------------------------------

# hadolint ignore=DL3017,DL3018
RUN \
  apk update  --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add     --quiet --no-cache \
    curl \
    jq \
    util-linux \
    mariadb \
    mariadb-client && \
  mkdir /etc/mysql/conf.d && \
  cp /etc/mysql/my.cnf /etc/mysql/my.cnf-DIST && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

COPY rootfs/ /

VOLUME ["/etc/mysql/conf.d"]

CMD ["/init/run.sh"]

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD /init/health_check.sh

# ---------------------------------------------------------------------------------------

EXPOSE 3306

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@boone-schulz.de>" \
  org.label-schema.build-date=${BUILD_DATE} \
  org.label-schema.name="MariaDB Docker Image" \
  org.label-schema.vcs-ref=${VCS_REF} \
  org.label-schema.description="Inofficial MariaDB Docker Image" \
  org.label-schema.url="https://www.mariadb.com" \
  org.label-schema.vcs-url="https://github.com/bodsch/docker-mariadb" \
  org.label-schema.vendor="Bodo Schulz" \
  org.label-schema.version=${MARIADB_VERSION} \
  org.label-schema.schema-version="1.0" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license="unlicense"

# ---------------------------------------------------------------------------------------
