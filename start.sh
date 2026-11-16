#!/bin/sh
# Start Prometheus on 127.0.0.1:19090 and the Caddy login gateway on $PORT.
set -eu

: "${PORT:=9090}"
: "${PROMETHEUS_USERNAME:=admin}"
: "${PROMETHEUS_RETENTION:=15d}"
DATA_DIR=/prometheus
INTERNAL=127.0.0.1:19090

if [ -z "${PROMETHEUS_PASSWORD:-}" ]; then
	echo "PROMETHEUS_PASSWORD is empty. Refusing to start Prometheus without a login." >&2
	exit 1
fi
if [ "$PORT" = "19090" ]; then
	echo "PORT 19090 is reserved for the internal Prometheus listener. Use another PORT." >&2
	exit 1
fi

mkdir -p "$DATA_DIR/config" "$DATA_DIR/data"
CONFIG="$DATA_DIR/config/prometheus.yml"
if [ -n "${PROMETHEUS_CONFIG:-}" ]; then
	CONFIG="$DATA_DIR/config/prometheus.from-env.yml"
	printf '%s\n' "$PROMETHEUS_CONFIG" > "$CONFIG"
	echo "Using the configuration from the PROMETHEUS_CONFIG variable."
elif [ ! -f "$CONFIG" ]; then
	cp /etc/railway/prometheus.yml "$CONFIG"
	echo "Wrote the default configuration to $CONFIG."
fi
promtool check config "$CONFIG"

if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
	EXTERNAL_URL="https://$RAILWAY_PUBLIC_DOMAIN/"
else
	EXTERNAL_URL="http://localhost:$PORT/"
fi

PROMETHEUS_PASSWORD_HASH=$(caddy hash-password --plaintext "$PROMETHEUS_PASSWORD")
export PORT PROMETHEUS_USERNAME PROMETHEUS_PASSWORD_HASH
export XDG_CONFIG_HOME=/tmp/caddy XDG_DATA_HOME=/tmp/caddy

set -- --config.file="$CONFIG" \
	--storage.tsdb.path="$DATA_DIR/data" \
	--storage.tsdb.retention.time="$PROMETHEUS_RETENTION" \
	--web.listen-address="$INTERNAL" \
	--web.external-url="$EXTERNAL_URL" \
	--web.route-prefix=/ \
	--web.enable-remote-write-receiver \
	--web.enable-otlp-receiver
if [ -n "${PROMETHEUS_RETENTION_SIZE:-}" ]; then
	set -- "$@" --storage.tsdb.retention.size="$PROMETHEUS_RETENTION_SIZE"
fi
# shellcheck disable=SC2086
/bin/prometheus "$@" ${PROMETHEUS_EXTRA_ARGS:-} &
PROM_PID=$!
caddy run --config /etc/railway/Caddyfile --adapter caddyfile &
CADDY_PID=$!

stop() {
	kill -TERM "$CADDY_PID" "$PROM_PID" 2>/dev/null || true
	wait "$PROM_PID" 2>/dev/null || true
	exit 0
}
trap stop TERM INT

# Exit (so Railway restarts the container) if either process stops.
while kill -0 "$PROM_PID" 2>/dev/null && kill -0 "$CADDY_PID" 2>/dev/null; do
	sleep 2 &
	wait $! || true
done
echo "Prometheus or the gateway stopped; exiting so Railway restarts the service." >&2
kill -TERM "$CADDY_PID" "$PROM_PID" 2>/dev/null || true
wait "$PROM_PID" 2>/dev/null || true
exit 1
