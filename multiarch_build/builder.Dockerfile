FROM golang:1.13

ARG TARGET_PROJECT

RUN mkdir -p /go/src/github.com/coreos/prometheus-operator
WORKDIR /go/src/github.com/coreos/prometheus-operator
RUN chmod -R 777 /go
COPY / /go/src/github.com/coreos/prometheus-operator

RUN mkdir -p /workspace/bin

RUN OS=linux ARCH=amd64 make ${TARGET_PROJECT} \
    && mv /go/src/github.com/coreos/prometheus-operator/${TARGET_PROJECT} \
    /workspace/bin/${TARGET_PROJECT}-linux-amd64

RUN OS=linux ARCH=arm64 make ${TARGET_PROJECT} \
    && mv /go/src/github.com/coreos/prometheus-operator/${TARGET_PROJECT} \
    /workspace/bin/${TARGET_PROJECT}-linux-arm64

RUN OS=linux ARCH=arm GOARM=7 make ${TARGET_PROJECT} \
    && mv /go/src/github.com/coreos/prometheus-operator/${TARGET_PROJECT} \
    /workspace/bin/${TARGET_PROJECT}-linux-arm