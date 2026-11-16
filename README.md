# Prometheus on Railway

A Railway template for [Prometheus](https://prometheus.io), the open-source metrics database and monitoring system. This repo builds the template's only service.

## What it deploys

- **Prometheus v3.16.0** from the official image `prom/prometheus:v3.16.0`, pinned by digest in the `Dockerfile`.
- **A login in front of it.** Prometheus has no login of its own, so a small [Caddy](https://caddyserver.com) 2.11.9 gateway in the same container asks for HTTP basic auth on every path except the status checks `/healthz` (Railway's health check), `/-/healthy` and `/-/ready`. Prometheus itself listens only on `127.0.0.1:19090` inside the container.
- **A Railway volume at `/prometheus`** for the time-series data (`/prometheus/data`) and the editable configuration (`/prometheus/config/prometheus.yml`).
- The remote-write receiver (`/api/v1/write`) and the OTLP receiver (`/api/v1/otlp/v1/metrics`) are on, behind the login, so apps can push metrics instead of being scraped.

## Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `PROMETHEUS_USERNAME` | `admin` | Login user for the web UI and API |
| `PROMETHEUS_PASSWORD` | generated (32 characters) | Login password. Prometheus refuses to start without one |
| `PROMETHEUS_RETENTION` | `15d` | How long samples are kept (`--storage.tsdb.retention.time`) |
| `PORT` | `9090` | Port of the gateway (public domain and private network) |
| `PROMETHEUS_PRIVATE_URL` | `http://${{RAILWAY_PRIVATE_DOMAIN}}:9090` | Reference this from Grafana or other services in the project |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `30` | Gives Prometheus time to close its database on redeploys |

Optional, not set by default:

- `PROMETHEUS_CONFIG`: a complete `prometheus.yml`. When set, it replaces the file on the volume at every start.
- `PROMETHEUS_RETENTION_SIZE`: a size limit such as `4GB` (`--storage.tsdb.retention.size`). Set it below your volume size.
- `PROMETHEUS_EXTRA_ARGS`: extra Prometheus flags, separated by spaces.

## Scrape targets

On first boot the default configuration is copied to `/prometheus/config/prometheus.yml`. It scrapes Prometheus itself. To add targets, either set `PROMETHEUS_CONFIG`, or edit the file with `railway ssh` and redeploy. Services in the same project are reachable over the private network, for example `my-app.railway.internal:8080`.

## Updates

Railway notifies everyone who deployed the template when this repo's `main` branch changes. Read [CHANGELOG.md](CHANGELOG.md) before you apply an update. Your data and configuration stay on the volume.
