## proxy-gen

A small utility that generates and validates nginx and Authelia configs from a single `config.yml`.

---

### Build

```bash
docker build -t proxy-gen .
```

---

### Run
```bash
docker run --rm \
  -v $(pwd)/config.yml:/app/config.yml \
  -v $(pwd)/nginx:/app/nginx \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e HOST_NGINX_PATH=$(pwd)/nginx \
  proxy-gen
```

---

### Using prebuilt image

```bash
docker run --rm \
  -v $(pwd)/config.yml:/app/config.yml \
  -v $(pwd)/nginx:/app/nginx \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e HOST_NGINX_PATH=$(pwd)/nginx \
  ghcr.io/dibaltzis/tools-collection/proxy-gen:latest
```
---

### Output

Generates the following structure:
```
nginx/
├── authelia
│   ├── configuration.yml
│   ├── db
│   └── users.yml
├── certs
│   ├── code-server-certificate.crt
│   ├── code-server-certificate.key
│   └── wildcard.cnf
└── conf.d
    └── default.conf
```

---

### How it works

1. Loads `config.yml`
2. Builds an internal context
3. Renders:
   - Authelia users & config
   - nginx config
   - certificates (optional)
4. Validates configs using Docker:
   - `authelia config validate`
   - `nginx -t`

---

### Requirements

- Docker
- Access to Docker socket (`/var/run/docker.sock`)

---

### Notes

- Designed for local / self-hosted setups
- Existing files are reused when possible
- Validation runs inside containers to match real runtime behavior

### Example

See `demo/` for a complete working setup.