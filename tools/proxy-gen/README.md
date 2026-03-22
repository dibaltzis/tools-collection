# Build
```bash 
docker build -t proxy-gen .
```

# Run

```bash
docker run --rm \
  -v $(pwd)/config.yml:/app/config.yml \
  -v $(pwd)/nginx:/app/nginx \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e HOST_NGINX_PATH=$(pwd)/nginx \
  proxy-gen
```
