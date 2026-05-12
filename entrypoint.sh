#!/bin/sh

set -e

RUNTIME_CONF=/tmp/hev-socks5-server.yml

: "${PORT:=1080}"
: "${LISTEN_ADDRESS:=::}"
: "${WORKERS:=4}"
: "${AUTH_FILE:=/data/auth.conf}"

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

is_true() {
    case "$1" in
        1|true|TRUE|yes|YES|on|ON)
            return 0
            ;;
    esac

    return 1
}

is_false_or_empty() {
    case "$1" in
        ''|0|false|FALSE|no|NO|off|OFF)
            return 0
            ;;
    esac

    return 1
}

is_uint "$PORT" || die "PORT must be a number"
[ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] || die "PORT must be between 1 and 65535"

is_uint "$WORKERS" || die "WORKERS must be a number"
[ "$WORKERS" -ge 1 ] || die "WORKERS must be greater than zero"

AUTH_MODE=none

if is_true "${AUTH_ENABLED:-}"; then
    if [ -n "${PROXY_USER+x}" ] || [ -n "${PROXY_PASSWORD+x}" ]; then
        [ -n "${PROXY_USER:-}" ] || die "PROXY_USER is required when PROXY_PASSWORD is set"
        [ -n "${PROXY_PASSWORD:-}" ] || die "PROXY_PASSWORD is required when PROXY_USER is set"
        AUTH_MODE=inline
    else
        [ -r "$AUTH_FILE" ] || die "AUTH_ENABLED=true, but auth file is not readable: $AUTH_FILE"
        [ -s "$AUTH_FILE" ] || die "AUTH_ENABLED=true, but auth file is empty: $AUTH_FILE"
        AUTH_MODE=file
    fi
elif is_false_or_empty "${AUTH_ENABLED:-}"; then
    AUTH_MODE=none
else
    die "AUTH_ENABLED must be true or false"
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

    case "$AUTH_MODE" in
        inline)
            cat <<EOF

auth:
  username: $(yaml_quote "$PROXY_USER")
  password: $(yaml_quote "$PROXY_PASSWORD")
EOF
            ;;
        file)
            cat <<EOF

auth:
  file: $(yaml_quote "$AUTH_FILE")
EOF
            ;;
    esac
} > "$RUNTIME_CONF"

exec /app/bin/hev-socks5-server "$RUNTIME_CONF"
