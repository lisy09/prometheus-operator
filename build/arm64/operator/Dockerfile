ARG ARCH="arm64"
ARG OS="linux"

FROM golang:1.13
RUN mkdir -p /go/src/github.com/coreos/prometheus-operator
WORKDIR /go/src/github.com/coreos/prometheus-operator
RUN chmod -R 777 /go
COPY / /go/src/github.com/coreos/prometheus-operator
COPY /build/arm64/Makefile /go/src/github.com/coreos/prometheus-operator/Makefile
RUN make operator

FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest
COPY --from=0 /go/src/github.com/coreos/prometheus-operator/operator /bin/operator
# On busybox 'nobody' has uid `65534'
USER 65534
ENTRYPOINT ["/bin/operator"]
