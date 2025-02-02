FROM ubuntu:20.04 as build

ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    apt-get update && \
    apt-get install -y build-essential git cmake software-properties-common \
    openssl libssl-dev pkg-config clang

RUN mkdir /src
WORKDIR /src

RUN mkdir /src/picoquic
COPY ./ /src/picoquic/

# Perl stuff is for the picotls test code
RUN echo install Test::TCP | perl -MCPAN -
RUN echo install Scope::Guard | perl -MCPAN -

RUN git clone https://github.com/h2o/picotls.git && \
    cd picotls && \
    git submodule init && \
    git submodule update && \
    cmake . && \
    make && \
    make check

RUN cd /src/picoquic && \
    cmake . && \
    make

FROM martenseemann/quic-network-simulator-endpoint:latest as tquic-interop

WORKDIR /

COPY --from=build \
     /src/picoquic/picoquicdemo \
     /picoquic/

COPY --from=build \
     /src/picoquic/run_endpoint.sh \
     /

RUN chmod u+x /run_endpoint.sh

ENTRYPOINT [ "./run_endpoint.sh" ]
