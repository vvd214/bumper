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
    print("true" if value else "false")
elif value is None:
    print("")
else:
    print(value)
PY
}

detect_host_ip() {
    python3 <<'PY'
import json
import os
import sys
import urllib.request

token = os.environ.get("SUPERVISOR_TOKEN")
if not token:
    sys.exit(1)

request = urllib.request.Request(
    "http://supervisor/network/info",
    headers={"Authorization": f"Bearer {token}"},
)

with urllib.request.urlopen(request, timeout=5) as response:
    payload = json.load(response)

interfaces = payload.get("data", {}).get("interfaces", [])
interfaces = sorted(interfaces, key=lambda item: not item.get("primary", False))
for interface in interfaces:
    ipv4 = interface.get("ipv4") or {}
    if not ipv4.get("ready", True) and not interface.get("primary", False):
        continue
    for address in ipv4.get("address") or []:
        ip = address.split("/", 1)[0]
        if ip and not ip.startswith("127."):
            print(ip)
            sys.exit(0)

sys.exit(1)
PY
}

BUMPER_SHARE="$(option data_path /share/bumper)"
mkdir -p "$BUMPER_SHARE/data" "$BUMPER_SHARE/certs"

repair_bumper_db() {
    db="$BUMPER_SHARE/data/bumper.db"

    python3 - "$db" <<'PY'
import json
import os
import shutil
import sys
from datetime import datetime

path = sys.argv[1]
os.makedirs(os.path.dirname(path), exist_ok=True)


def backup_invalid_db():
    if not os.path.exists(path):
        return

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = f"{path}.corrupt-autobak.{stamp}"
    shutil.copy2(path, backup_path)
    print(f"Backed up invalid Bumper database to {backup_path}")


def write_db(data):
    temp_path = f"{path}.tmp"
    with open(temp_path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, separators=(",", ":"))
    os.replace(temp_path, path)


if not os.path.exists(path) or os.path.getsize(path) == 0:
    write_db({})
    print("Created empty Bumper database.")
    sys.exit(0)

try:
    with open(path, encoding="utf-8") as file:
        text = file.read()
    json.loads(text)
    print("Bumper database JSON check passed.")
    sys.exit(0)
except Exception as error:
    first_error = error

try:
    decoder = json.JSONDecoder()
    data, end = decoder.raw_decode(text)
    backup_invalid_db()
    write_db(data)
    print(f"Repaired Bumper database by removing trailing invalid data after byte {end}.")
except Exception:
    backup_invalid_db()
    write_db({})
    print(f"Reset invalid Bumper database: {first_error}")
PY
}

repair_bumper_db

export BUMPER_DATA="$BUMPER_SHARE/data"
export BUMPER_CERTS="$BUMPER_SHARE/certs"
export BUMPER_LISTEN="$(option listen 0.0.0.0)"
export BUMPER_MQTT_ADMIN_USERS="$(option mqtt_admin_users admin)"
export DEBUG_BUMPER_LEVEL="$(option debug_level INFO)"
export DEBUG_BUMPER_VERBOSE="$(option debug_verbose 1)"
export SYNC_TIMEZONE="$(option sync_timezone false)"

ANNOUNCE_IP="$(option announce_ip "")"
if [ -z "$ANNOUNCE_IP" ]; then
    ANNOUNCE_IP="$(detect_host_ip || true)"
fi
if [ -n "$ANNOUNCE_IP" ]; then
    export BUMPER_ANNOUNCE_IP="$ANNOUNCE_IP"
fi

echo "Using Bumper data path: $BUMPER_SHARE"
echo "Using BUMPER_ANNOUNCE_IP: ${BUMPER_ANNOUNCE_IP:-auto}"
echo "Using BUMPER_MQTT_ADMIN_USERS: ${BUMPER_MQTT_ADMIN_USERS:-none}"

exec /bumper/.venv/bin/bumper
