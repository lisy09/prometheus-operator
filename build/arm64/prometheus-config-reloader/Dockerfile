ARG ARCH="arm64"
ARG OS="linux"

FROM golang:1.13
RUN mkdir -p /go/src/github.com/coreos/prometheus-operator
WORKDIR /go/src/github.com/coreos/prometheus-operator
RUN chmod -R 777 /go
COPY / /go/src/github.com/coreos/prometheus-operator
COPY /build/arm64/Makefile /go/src/github.com/coreos/prometheus-operator/Makefile
RUN make prometheus-config-reloader

FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest
COPY --from=0 /go/src/github.com/coreos/prometheus-operator/prometheus-config-reloader /bin/prometheus-config-reloader
USER nobody
ENTRYPOINT ["/bin/prometheus-config-reloader"]
