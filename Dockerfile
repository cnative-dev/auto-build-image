ARG DOCKER_VERSION

FROM docker:${DOCKER_VERSION}

RUN apk add bash ruby wget
RUN apk add ruby-etc
RUN wget https://github.com/buildpacks/pack/releases/download/v0.12.0/pack-v0.12.0-linux.tgz && \
    tar xvf pack-v0.12.0-linux.tgz && \
    rm pack-v0.12.0-linux.tgz && \
    mv pack /usr/local/bin/pack
COPY src/ build/
CMD ["/build/build.sh"]
