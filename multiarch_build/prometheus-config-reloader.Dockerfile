FROM quay.io/prometheus/busybox:latest

ARG prometheus-config-reloader
ARG TARGETOS
ARG TARGETARCH

COPY /bin/prometheus-config-reloader-${TARGETOS}-${TARGETARCH} \
    /bin/prometheus-config-reloader
USER nobody
ENTRYPOINT ["/bin/prometheus-config-reloader"]