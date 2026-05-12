# hev-socks5-server-docker

Lightweight container image for [hev-socks5-server](https://github.com/heiher/hev-socks5-server).

## Build

```bash
docker build -t hev-socks5-server .
```

## Run

- Without authentication:
    ```bash
    docker run --rm -it \
      -p 1080:1080 \
      hev-socks5-server
    ```

- With custom port:
    ```bash
    docker run --rm -it \
      -p 1081:1081 \
      -e PORT=1081 \
      hev-socks5-server
    ```

## Authentication

Authentication is disabled by default.

- Enable authentication with username and password:
    ```bash
    docker run --rm -it \
      -p 1080:1080 \
      -e AUTH_ENABLED=true \
      -e PROXY_USER=user \
      -e PROXY_PASSWORD=passwd \
      hev-socks5-server
    ```

- Or use an auth file:
    ```bash
    docker run --rm -it \
      -p 1080:1080 \
      -e AUTH_ENABLED=true \
      -v ./data:/data:ro \
      hev-socks5-server
    ```

- Example `./data/auth.conf`:
    ```plaintext
    user passwd 0x0
    another_user another_passwd 0x0
    ```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `1080` | SOCKS5 listen port |
| `LISTEN_ADDRESS` | `::` | Listen address |
| `WORKERS` | `4` | Worker threads |
| `AUTH_ENABLED` | `false` | Enable authentication |
| `PROXY_USER` | - | SOCKS5 username |
| `PROXY_PASSWORD` | - | SOCKS5 password |
| `AUTH_FILE` | `/data/auth.conf` | Auth file path |
| `LOG_LEVEL` | `warn` | Log level: `debug`, `info`, `warn`, or `error` |
| `LOG_FILE` | `stderr` | Log output: `stderr` or `stdout` |
