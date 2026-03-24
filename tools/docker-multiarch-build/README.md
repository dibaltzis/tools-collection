# docker-multiarch-build

Small scripts to build and push multi-architecture Docker images.

Supports:
- GHCR (`ghcr.io`)
- private registries
- local execution and Jenkins

---

### Files

```
.
├── build-ghcr.sh
├── build-registry.sh
└── Jenkinsfile
```

---

### Usage (private registry)

```bash
export REGISTRY=your-registry-ip
export IMAGE=project-name-placeholder

./build-registry.sh
```

---

### Usage (GHCR)

```bash
export GITHUB_USER=your-username
export IMAGE=project-name-placeholder

# optional (if not using gh CLI)
export GHCR_TOKEN=your-token

./build-ghcr.sh
```

---

### Jenkins

Uses `Jenkinsfile`.

Default:
- builds and pushes to private registry

For GHCR:
- switch to `build-ghcr.sh`
- provide `GHCR_TOKEN` via Jenkins credentials

---

### Environment variables

- `IMAGE`
- `REGISTRY`
- `GITHUB_USER` (GHCR only)
- `GHCR_TOKEN` (GHCR only)
- `VERSION` (optional, defaults to git commit or `dev`)

---

### Output

- Multi-arch images (`amd64`, `arm64`)
- Tags:
  - `<image>:<git-sha>`
  - `<image>:latest`