ARG VERSION=2.13.1

FROM docker.io/alpine:3.23 AS builder

ARG VERSION

RUN apk add --no-cache make gcc musl-dev

WORKDIR /build

RUN wget -O source.tar.gz https://github.com/heiher/hev-socks5-server/releases/download/${VERSION}/hev-socks5-server-${VERSION}.tar.xz

RUN tar xfv source.tar.gz --strip-components=1

RUN make ENABLE_STATIC=1 INSTDIR="/app" -j$(nproc) install && \
    make clean && \
    rm -rf /build/*


FROM docker.io/busybox:stable-uclibc AS main

COPY --from=builder /app /app

COPY ./entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

STOPSIGNAL SIGINT

ENTRYPOINT [ "/app/entrypoint.sh" ]
