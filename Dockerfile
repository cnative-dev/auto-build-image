ARG BUILDX_VERSION=0.8.0
ARG DOCKER_VERSION

FROM docker/buildx-bin:${BUILDX_VERSION} as buildx-bin
FROM docker:${DOCKER_VERSION}

ARG TARGETARCH
ARG PACK_VERSION=v0.24.0

RUN apk upgrade --available --no-cache && \
     apk add --no-cache bash ruby ruby-etc wget
RUN wget https://github.com/buildpacks/pack/releases/download/${PACK_VERSION}/pack-${PACK_VERSION}-linux.tgz && \
    tar xvf pack-${PACK_VERSION}-linux.tgz && \
    rm pack-${PACK_VERSION}-linux.tgz && \
    mv pack /usr/local/bin/pack

COPY --from=buildx-bin /buildx /usr/libexec/docker/cli-plugins/docker-buildx

COPY src/ build/
CMD ["/build/build.sh"]
