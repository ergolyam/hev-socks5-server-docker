#!/bin/sh

set -e

RUNTIME_CONF=/tmp/hev-socks5-server.yml

: "${PORT:=1080}"
: "${LISTEN_ADDRESS:=::}"
: "${WORKERS:=4}"

die() {
    echo "entrypoint: $*" >&2
    exit 1
}

is_uint() {
    case "$1" in
        ''|*[!0-9]*)
            return 1
            ;;
    esac
    return 0
}

yaml_quote() {
    # YAML single-quoted scalar.
    # Single quote is escaped as two single quotes.
    printf "'"
    printf '%s' "$1" | sed "s/'/''/g"
    printf "'"
}

is_uint "$PORT" || die "PORT must be a number"
[ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] || die "PORT must be between 1 and 65535"

is_uint "$WORKERS" || die "WORKERS must be a number"
[ "$WORKERS" -ge 1 ] || die "WORKERS must be greater than zero"

AUTH_ENABLED=0

if [ -n "${PROXY_USER+x}" ] || [ -n "${PROXY_PASSWORD+x}" ]; then
    [ -n "${PROXY_USER:-}" ] || die "PROXY_USER is required when auth is enabled"
    [ -n "${PROXY_PASSWORD:-}" ] || die "PROXY_PASSWORD is required when auth is enabled"
    AUTH_ENABLED=1
fi

{
    cat <<EOF
main:
  workers: $WORKERS
  port: $PORT
  listen-address: $(yaml_quote "$LISTEN_ADDRESS")
  listen-ipv6-only: false
  bind-address: ''
  bind-address-v4: ''
  bind-address-v6: ''
  bind-interface: ''
  domain-address-type: unspec
  mark: 0
EOF

    if [ "$AUTH_ENABLED" -eq 1 ]; then
        cat <<EOF

auth:
  username: $(yaml_quote "$PROXY_USER")
  password: $(yaml_quote "$PROXY_PASSWORD")
EOF
    fi
} > "$RUNTIME_CONF"

exec /app/bin/hev-socks5-server "$RUNTIME_CONF"
