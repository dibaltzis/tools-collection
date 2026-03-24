# jenkins-agent-custom-ca

Jenkins inbound agent with Docker and optional custom CA support.

Useful for:
- private Docker registries
- self-signed certificates

---

### Build

1. Place your certificate next to the Dockerfile:
   ```
   certificate.crt
   ```

2. Build the image:
   ```bash
   docker build --build-arg INSTALL_CUSTOM_CA=true -t jenkins-docker-agent .
   ```

---

### Usage

Update `docker-compose.yml`:

- `JENKINS_URL`
- `JENKINS_SECRET`
- volume paths if needed

Then run:

```bash
docker compose up -d
```

---

### Notes

- Mounts Docker socket for build/push operations
- Installs CA into both system and Java trust store
- Required when interacting with private registries