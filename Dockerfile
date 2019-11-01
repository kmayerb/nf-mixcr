FROM openjdk:11

ARG version="3.0.11"

RUN mkdir /work

RUN cd / \
    && wget -q https://github.com/milaboratory/mixcr/releases/download/v${version}/mixcr-${version}.zip \
    && unzip mixcr-${version}.zip \
    && mv mixcr-${version} mixcr \
    && rm mixcr-${version}.zip

ENV PATH="/mixcr:${PATH}"

WORKDIR /work

ENTRYPOINT ["/bin/bash"]