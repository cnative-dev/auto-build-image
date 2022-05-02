ARG DOCKER_VERSION

FROM docker:${DOCKER_VERSION}

ARG TARGETARCH
ARG BUILDX_VERSION
ARG PACK_VERSION

RUN apk upgrade --available --no-cache && \
    apk add --no-cache bash ruby ruby-etc wget
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
      wget https://github.com/buildpacks/pack/releases/download/${PACK_VERSION}/pack-${PACK_VERSION}-linux-${TARGETARCH}.tgz \
      -O pack-${PACK_VERSION}-linux.tgz; \
    else \
      wget https://github.com/buildpacks/pack/releases/download/${PACK_VERSION}/pack-${PACK_VERSION}-linux.tgz; \
    fi && \
    tar xvf pack-${PACK_VERSION}-linux.tgz && \
    rm pack-${PACK_VERSION}-linux.tgz && \
    mv pack /usr/local/bin/pack
RUN mkdir -p /usr/libexec/docker/cli-plugins/ && \
    wget https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${TARGETARCH} \
    -O /usr/libexec/docker/cli-plugins/docker-buildx && \
    chmod a+x /usr/libexec/docker/cli-plugins/docker-buildx

COPY src/ build/

CMD ["/build/build.sh"]
