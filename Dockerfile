ARG DOCKER_VERSION

FROM docker:${DOCKER_VERSION}

ARG PACK_VERSION=v0.18.0

RUN apk add --no-cache bash ruby ruby-etc wget
RUN wget https://github.com/buildpacks/pack/releases/download/${PACK_VERSION}/pack-${PACK_VERSION}-linux.tgz && \
    tar xvf pack-${PACK_VERSION}-linux.tgz && \
    rm pack-${PACK_VERSION}-linux.tgz && \
    mv pack /usr/local/bin/pack

ARG TARGETARCH
ARG BUILDX_VERSION=v0.5.1
RUN mkdir -p /usr/local/libexec/docker/cli-plugins && \
    wget https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${TARGETARCH} \
      -O /usr/local/libexec/docker/cli-plugins/docker-buildx && \
    chmod a+x /usr/local/libexec/docker/cli-plugins/docker-buildx

COPY src/ build/
CMD ["/build/build.sh"]
