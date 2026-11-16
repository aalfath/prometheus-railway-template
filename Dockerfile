# Prometheus for Railway: official image plus a small Caddy gateway that adds a login.
# Caddy only provides the binary; it is a static Go build.
FROM caddy:2.11.9@sha256:4e2425f6009577e7c651010f16679c28f7d12df3e7b1914f941a7a3370746b3c AS caddy

FROM prom/prometheus:v3.16.0@sha256:e04987641b57704f408e31f6373ba4138ecf27cb4a165d24aabb6c38fddd0f06

COPY --from=caddy /usr/bin/caddy /bin/caddy
COPY Caddyfile /etc/railway/Caddyfile
COPY prometheus.yml /etc/railway/prometheus.yml
COPY start.sh /etc/railway/start.sh

# Railway volumes are owned by root, so run as root to write /prometheus.
USER root
ENV PORT=9090
EXPOSE 9090
WORKDIR /prometheus

ENTRYPOINT ["/bin/sh", "/etc/railway/start.sh"]
CMD []
