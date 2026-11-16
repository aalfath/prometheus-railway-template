# Changelog

## 3.16.0-2 (2026-11-16)

- README: add the Deploy on Railway button for the published template `prometheus-2`. No change to the service.

## 3.16.0-1 (2026-11-16)

- First release: Prometheus v3.16.0 (`prom/prometheus:v3.16.0@sha256:e04987641b57704f408e31f6373ba4138ecf27cb4a165d24aabb6c38fddd0f06`) behind a Caddy 2.11.9 basic-auth gateway, data and configuration on a volume at `/prometheus`, remote-write and OTLP receivers on behind the login.
