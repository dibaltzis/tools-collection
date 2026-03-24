FROM jenkins/inbound-agent:latest

ARG INSTALL_CUSTOM_CA=false
ARG CA_ALIAS=custom-ca

USER root

# Ensure required tools exist
RUN apt-get update && \
    apt-get install -y ca-certificates docker.io docker-buildx && \
    rm -rf /var/lib/apt/lists/*

# Optional CA install
COPY certificate.crt /tmp/certificate.crt

RUN if [ "$INSTALL_CUSTOM_CA" = "true" ]; then \
      cp /tmp/certificate.crt /usr/local/share/ca-certificates/certificate.crt && \
      update-ca-certificates && \
      CACERTS=$(readlink -f "$(dirname "$(readlink -f "$(which java)")")/../lib/security/cacerts") && \
      keytool -importcert \
        -file /usr/local/share/ca-certificates/certificate.crt \
        -alias "$CA_ALIAS" \
        -keystore "$CACERTS" \
        -storepass changeit \
        -noprompt ; \
    else \
      echo "Skipping custom CA installation"; \
    fi

USER jenkins
