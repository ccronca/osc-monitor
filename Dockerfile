FROM registry.redhat.io/ubi9/ubi-minimal:latest AS builder

ENV USER_UID=1001 \
USER_NAME=openshift-sandboxed-containers-operator

RUN microdnf -y install golang make git

WORKDIR /
RUN git clone https://github.com/kata-containers/kata-containers.git
WORKDIR /kata-containers/src/runtime

RUN CGO_ENABLED=1 GOFLAGS=-tags=strictfipsruntime make monitor

FROM registry.redhat.io/ubi9/ubi-minimal:latest
LABEL name="openshift-sandboxed-containers-operator-monitor" \
version="${CI_VERSION}" \
com.redhat.component="osc-monitor-container" \
summary="osc-monitor provides the kata-monitor binary to expose sandboxed containers custom metrics" \
maintainer="support@redhat.com" \
description="osc-monitor provides the kata-monitor binary to expose sandboxed containers custom metrics" \
io.k8s.display-name="openshift-sandboxed-containers-monitor"

COPY --from=builder /kata-containers/src/runtime/kata-monitor /usr/bin/kata-monitor

# Add only required capabilities for the monitor
RUN chmod u-s /usr/bin/kata-monitor
RUN setcap "cap_dac_override+eip" /usr/bin/kata-monitor

CMD ["-h"]
ENTRYPOINT ["/usr/bin/kata-monitor"]
