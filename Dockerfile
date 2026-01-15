##
# Custom Keycloak build (from this repo) + GHCR-friendly image
#
# Features:
# - Build Keycloak distribution from source (this repository)
# - Multi-stage image build (smaller runtime)
# - Supports custom providers, themes, and realm import
# - Runs `kc.sh build` during image build for production optimization
#
# Customization folders (optional):
# - docker/providers/*.jar  -> copied to /opt/keycloak/providers/
# - docker/themes/**        -> copied to /opt/keycloak/themes/
# - docker/realm/*.json     -> copied to /opt/keycloak/data/import/
##

############################
# 1) Build Keycloak dist
############################
FROM eclipse-temurin:21-jdk AS dist-build

WORKDIR /workspace

# For reproducible builds in CI
ENV MAVEN_OPTS="-Djava.awt.headless=true"

# Copy full source (Keycloak build needs the multi-module repo)
COPY . .

# Build the Quarkus distribution (produces zip + tar.gz in quarkus/dist/target)
# Notes:
# - Keep tests off for CI speed; run tests in a separate workflow if needed.
# - Use Maven Wrapper to ensure correct Maven version.
# On Windows checkouts, mvnw can be CRLF which breaks execution in Linux containers (`./mvnw: not found`).
# Normalize line endings and make it executable before running.
RUN sed -i 's/\r$//' mvnw && chmod +x mvnw && ./mvnw -pl quarkus/deployment,quarkus/dist -am -DskipTests clean install

############################
# 2) Assemble runtime fs + optimize build
############################
FROM registry.access.redhat.com/ubi9 AS ubi-micro-build

ARG KEYCLOAK_VERSION=999.0.0-SNAPSHOT
ARG KEYCLOAK_BUILD_DB=postgres
ARG KEYCLOAK_HEALTH_ENABLED=true
ARG KEYCLOAK_METRICS_ENABLED=true

# Need tar/gzip to unpack dist; need java to run kc.sh build (Quarkus augmentation)
RUN dnf install -y tar gzip java-21-openjdk-headless glibc-langpack-en findutils && \
    dnf clean all

RUN mkdir -p /tmp/keycloak

# Copy the built distribution archive from the previous stage
COPY --from=dist-build /workspace/quarkus/dist/target/keycloak-*.tar.gz /tmp/keycloak/keycloak.tar.gz

RUN tar -xvf /tmp/keycloak/keycloak.tar.gz -C /tmp/keycloak && \
    rm -f /tmp/keycloak/keycloak.tar.gz && \
    mv /tmp/keycloak/keycloak-* /opt/keycloak && \
    mkdir -p /opt/keycloak/data

# --- Optional customizations (safe if folders don't exist in build context) ---
# Providers (SPI) jars (recommended place for custom providers/theme JARs)
COPY docker/providers/ /opt/keycloak/providers/
# Theme JAR already tracked in this repo for local dev (`js/apps/keycloak-server/...`).
# This is a Keycloak "theme as JAR" approach (e.g. keycloakify), so no folder theme is required.
COPY js/apps/keycloak-server/server/providers/*.jar /opt/keycloak/providers/
# Folder-based themes (optional). Keep for teams that still ship themes as files.
COPY docker/themes/ /opt/keycloak/themes/
# Realm import files (use `--import-realm` at runtime)
COPY docker/realm/ /opt/keycloak/data/import/

# Ensure group writable permissions (OpenShift-friendly)
RUN chmod -R g+rwX /opt/keycloak

# Build-time optimization (recommended for production images)
# - Build with a default DB driver (postgres by default); can be overridden via build-arg
RUN /opt/keycloak/bin/kc.sh build \
    --db=${KEYCLOAK_BUILD_DB} \
    --health-enabled=${KEYCLOAK_HEALTH_ENABLED} \
    --metrics-enabled=${KEYCLOAK_METRICS_ENABLED}

# Build minimal rootfs for ubi-micro (includes java + small shell utils + curl for /health checks)
COPY quarkus/container/ubi-null.sh /tmp/ubi-null.sh
RUN bash /tmp/ubi-null.sh java-21-openjdk-headless glibc-langpack-en findutils curl-minimal

############################
# 3) Final runtime image (UBI micro)
############################
FROM registry.access.redhat.com/ubi9-micro

ENV LANG=en_US.UTF-8
# Flag for determining app is running in container
ENV KC_RUN_IN_CONTAINER=true

COPY --from=ubi-micro-build /tmp/null/rootfs/ /
COPY --from=ubi-micro-build --chown=1000:0 /opt/keycloak /opt/keycloak

RUN echo "keycloak:x:0:root" >> /etc/group && \
    echo "keycloak:x:1000:0:keycloak user:/opt/keycloak:/sbin/nologin" >> /etc/passwd

USER 1000

EXPOSE 8080
EXPOSE 8443
EXPOSE 9000

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

# OCI labels (friendly defaults; override in CI via build-args)
ARG KEYCLOAK_VERSION
ARG VCS_REF=""
ARG BUILD_DATE=""

LABEL org.opencontainers.image.title="Keycloak (custom build)" \
      org.opencontainers.image.description="Custom Keycloak build from source with optional providers/themes/realm import" \
      org.opencontainers.image.source="https://github.com/keycloak/keycloak" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${KEYCLOAK_VERSION}"

