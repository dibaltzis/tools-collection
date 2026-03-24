# Demo

A minimal working example using `proxy-gen` with nginx + Authelia.

## Run

```bash
cd demo

# 1. Edit config
# Set your actual IP in config.yml (used with nip.io)

# 2. Generate nginx + Authelia configuration
docker run --rm \
  -v $(pwd)/config.yml:/app/config.yml \
  -v $(pwd)/nginx:/app/nginx \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e HOST_NGINX_PATH=$(pwd)/nginx \
  ghcr.io/dibaltzis/tools-collection/proxy-gen:latest

# 3. Start the stack
docker compose up -d
```

---

## Access
- `https://app.<your-ip>.nip.io`

---

## Demo Credentials

- Username: `demo`
- Password: `demo`

---