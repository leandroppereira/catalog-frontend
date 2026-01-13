#!/bin/sh
set -eu

# BACKEND_URL já vem do ENV definido no Containerfile (via CATALOG_API_URL)
# Mas deixamos fallback seguro:
BACKEND_URL="${BACKEND_URL:-}"

cat >/tmp/config.js <<EOF
window.__CONFIG__ = {
  BACKEND_URL: "${BACKEND_URL}"
};
EOF

exec nginx -g "daemon off;"