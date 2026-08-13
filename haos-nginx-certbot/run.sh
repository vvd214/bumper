#!/usr/bin/env sh
set -eu

OPTIONS_FILE=/data/options.json

option() {
    key="$1"
    default="$2"
    python3 - "$OPTIONS_FILE" "$key" "$default" <<'PY'
import json
import sys

path, key, default = sys.argv[1:4]
try:
    with open(path, encoding="utf-8") as file:
        data = json.load(file)
except FileNotFoundError:
    data = {}

value = data.get(key, default)
if isinstance(value, bool):
    print("1" if value else "0")
elif value is None:
    print("")
else:
    print(value)
PY
}

LEGACY_DATA_PATH="$(option bumper_path "")"
DATA_PATH="$(option data_path "${LEGACY_DATA_PATH:-/share/bumper}")"
CONFIG_DIR="${DATA_PATH}/configs"
NGINX_CONFIG="${CONFIG_DIR}/nginx.conf"
USER_CONFIG_DIR="${CONFIG_DIR}/user_conf.d"
LETSENCRYPT_DIR="${CONFIG_DIR}/letsencrypt"
ENV_FILE="${CONFIG_DIR}/nginx-certbot.env"

if [ ! -f "$NGINX_CONFIG" ]; then
    echo "Missing nginx config: $NGINX_CONFIG"
    exit 1
fi

mkdir -p "$USER_CONFIG_DIR" "$LETSENCRYPT_DIR"

if [ -f "$ENV_FILE" ]; then
    set -a
    . "$ENV_FILE"
    set +a
fi

OPTION_EMAIL="$(option certbot_email "")"
if [ -n "$OPTION_EMAIL" ]; then
    export CERTBOT_EMAIL="$OPTION_EMAIL"
fi

export RENEWAL_INTERVAL="$(option renewal_interval "${RENEWAL_INTERVAL:-5d}")"
export STAGING="$(option staging "${STAGING:-0}")"

if [ -z "${CERTBOT_EMAIL:-}" ]; then
    echo "CERTBOT_EMAIL is required. Set certbot_email in add-on options or CERTBOT_EMAIL in ${ENV_FILE}."
    exit 1
fi

rm -f /etc/nginx/nginx.conf
ln -s "$NGINX_CONFIG" /etc/nginx/nginx.conf

rm -rf /etc/nginx/user_conf.d
ln -s "$USER_CONFIG_DIR" /etc/nginx/user_conf.d

mkdir -p /etc/letsencrypt
if [ "$(find "$LETSENCRYPT_DIR" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)" -gt 0 ]; then
    cp -a "$LETSENCRYPT_DIR/." /etc/letsencrypt/
fi

sync_letsencrypt() {
    mkdir -p "$LETSENCRYPT_DIR"
    cp -a /etc/letsencrypt/. "$LETSENCRYPT_DIR/"
}

(
    while true; do
        sleep 300
        sync_letsencrypt
    done
) &
SYNC_PID=$!

trap 'sync_letsencrypt; kill "${SYNC_PID}" 2>/dev/null || true' EXIT INT TERM

echo "Using data path: $DATA_PATH"
echo "Using Nginx config: $NGINX_CONFIG"
echo "Using Certbot email: $CERTBOT_EMAIL"

/docker-entrypoint.sh /scripts/start_nginx_certbot.sh &
APP_PID=$!
wait "$APP_PID"
