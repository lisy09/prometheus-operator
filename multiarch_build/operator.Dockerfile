FROM quay.io/prometheus/busybox:latest

ARG operator
ARG TARGETOS
ARG TARGETARCH

COPY /bin/operator-${TARGETOS}-${TARGETARCH} \
    /bin/operator
USER nobody
ENTRYPOINT ["/bin/operator"]