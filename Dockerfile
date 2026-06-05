FROM node:18-alpine

RUN apk add --no-cache nginx

WORKDIR /app
RUN mkdir -p /app/config /app/data

COPY frontend/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

# 复制后端代码，但排除 node_modules
COPY backend/package*.json backend/pnpm-lock.yaml* /app/

# 安装 pnpm 和依赖（在 ARMv7 原生环境下安装，sqlite3 会下载预编译包）
RUN npm install -g pnpm && pnpm install --production

COPY backend/ /app/

VOLUME ["/app/config", "/app/data"]
EXPOSE 8008

COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh
ENTRYPOINT ["/app/docker-entrypoint.sh"]
