ARG DOCKER_VERSION

FROM docker:${DOCKER_VERSION}

ARG PACK_VERSION=v0.18.0

RUN apk add --no-cache bash ruby ruby-etc wget
RUN wget https://github.com/buildpacks/pack/releases/download/${PACK_VERSION}/pack-${PACK_VERSION}-linux.tgz && \
    tar xvf pack-${PACK_VERSION}-linux.tgz && \
    rm pack-${PACK_VERSION}-linux.tgz && \
    mv pack /usr/local/bin/pack
COPY src/ build/
CMD ["/build/build.sh"]
