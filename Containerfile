# -------- Build stage --------
FROM docker.io/library/node:20-alpine AS build
WORKDIR /app

# Copia manifestos e instala deps
COPY package*.json ./
RUN npm install

# Copia o restante do código e gera build
COPY . .
RUN npm run build

# -------- Runtime stage --------
FROM docker.io/nginxinc/nginx-unprivileged:stable-alpine

# Recebe URL do backend via build-arg (vindo do template)
ARG CATALOG_API_URL
# Converte build-arg em env runtime (para não precisar oc set env)
ENV BACKEND_URL=${CATALOG_API_URL}

# Nginx config (serve SPA + /config.js)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Conteúdo estático gerado pelo build
COPY --from=build /app/dist /usr/share/nginx/html

# Entrypoint que escreve /tmp/config.js (gravável) e sobe nginx
COPY entrypoint.sh /entrypoint.sh

EXPOSE 8080
CMD ["sh","/entrypoint.sh"]
