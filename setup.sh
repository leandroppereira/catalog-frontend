#!/usr/bin/env bash
set -euo pipefail

# ========= Config =========
PROJECT="petrol"
FRONTEND_NAME="catalog-frontend"
BACKEND_ROUTE_NAME="catalog-backend"
# ==========================

echo "==> Validando login no OpenShift..."
oc whoami >/dev/null

echo "==> Selecionando projeto: ${PROJECT}"
if oc get project "${PROJECT}" >/dev/null 2>&1; then
  oc project "${PROJECT}" >/dev/null
else
  oc new-project "${PROJECT}" >/dev/null
fi

echo "==> Obtendo URL do backend a partir da Route '${BACKEND_ROUTE_NAME}'..."
BACKEND_HOST="$(oc get route "${BACKEND_ROUTE_NAME}" -o jsonpath='{.spec.host}' 2>/dev/null || true)"
if [[ -z "${BACKEND_HOST}" ]]; then
  echo "ERRO: Não encontrei a route '${BACKEND_ROUTE_NAME}' no projeto '${PROJECT}'."
  echo "Crie/exponha o backend antes e tente novamente."
  exit 1
fi
BACKEND_URL="https://${BACKEND_HOST}"
echo "    BACKEND_URL=${BACKEND_URL}"

echo "==> Verificando se os arquivos do frontend existem no diretório atual..."
for f in Dockerfile package.json index.html nginx.conf entrypoint.sh; do
  if [[ ! -f "${f}" ]]; then
    echo "ERRO: Arquivo obrigatório não encontrado: ${f}"
    echo "Execute este script dentro da pasta do frontend (onde estão Dockerfile, package.json, etc.)."
    exit 1
  fi
done
if [[ ! -d "src" ]]; then
  echo "ERRO: Diretório obrigatório não encontrado: src/"
  exit 1
fi

echo "==> Criando BuildConfig (binary docker strategy) se não existir: ${FRONTEND_NAME}"
if oc get bc "${FRONTEND_NAME}" >/dev/null 2>&1; then
  echo "    - BuildConfig já existe (ok)"
else
  oc new-build --name="${FRONTEND_NAME}" --binary --strategy=docker >/dev/null
fi

echo "==> Iniciando build do frontend a partir do diretório atual: $(pwd)"
oc start-build "${FRONTEND_NAME}" --from-dir=. --follow

echo "==> Criando app (Deployment/Service) se não existir: ${FRONTEND_NAME}"
if oc get deploy "${FRONTEND_NAME}" >/dev/null 2>&1; then
  echo "    - Deployment já existe (ok)"
else
  oc new-app "${FRONTEND_NAME}" >/dev/null
fi

echo "==> Configurando variável de ambiente BACKEND_URL no Deployment..."
oc set env deploy/"${FRONTEND_NAME}" BACKEND_URL="${BACKEND_URL}" >/dev/null

echo "==> Garantindo /tmp gravável (emptyDir) no Deployment..."
oc set volume deploy/"${FRONTEND_NAME}" \
  --add --name=tmp \
  --type=emptyDir \
  --mount-path=/tmp \
  --overwrite >/dev/null

echo "==> Aguardando rollout do frontend..."
oc rollout status deploy/"${FRONTEND_NAME}" --timeout=180s

echo "==> Criando Route edge (se não existir): ${FRONTEND_NAME}"
if oc get route "${FRONTEND_NAME}" >/dev/null 2>&1; then
  echo "    - Route já existe (ok)"
else
  oc create route edge "${FRONTEND_NAME}" \
    --service="${FRONTEND_NAME}" \
    --insecure-policy=Allow >/dev/null
fi

FRONT_HOST="$(oc get route "${FRONTEND_NAME}" -o jsonpath='{.spec.host}')"

echo
echo "==> Concluído!"
echo "Frontend URL:"
echo "  https://${FRONT_HOST}"
echo
echo "Testes:"
echo "  curl -k https://${FRONT_HOST}/config.js"
echo "  curl -k https://${FRONT_HOST}/"
