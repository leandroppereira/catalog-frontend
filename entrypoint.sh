#!/bin/sh
set -eu

BACKEND_URL="${BACKEND_URL:-}"

cat >/tmp/config.js <<EOF
window.__CONFIG__ = {
  BACKEND_URL: "${BACKEND_URL}"
};
EOF

exec nginx -g "daemon off;"
