FROM python:3.12-slim

# Create non-root user
RUN useradd -m appuser

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (official)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    pyyaml \
    jinja2

# Copy app code
COPY app/core /app/core
COPY app/main.py /app/main.py
COPY app/templates /app/templates

# Ensure permissions
RUN chown -R appuser:appuser /app

# Run generator
ENTRYPOINT ["python", "main.py"]