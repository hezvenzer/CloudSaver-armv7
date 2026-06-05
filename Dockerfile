# ============================================
# 前端构建阶段（强制在构建机原生平台运行）
# ============================================
FROM --platform=$BUILDPLATFORM node:18-alpine AS frontend-build
WORKDIR /app

RUN npm install -g pnpm

COPY frontend/package*.json ./
RUN pnpm install

COPY frontend/ ./
RUN npm run build

# ============================================
# 后端构建阶段（同样在原生平台）
# ============================================
FROM --platform=$BUILDPLATFORM node:18-alpine AS backend-build
WORKDIR /app

RUN npm install -g pnpm

COPY backend/package*.json ./
RUN pnpm install

COPY backend/ ./
RUN rm -f database.sqlite
RUN npm run build

# ============================================
# 生产环境镜像（ARMv7 目标平台）
# ============================================
FROM node:18-alpine

RUN apk add --no-cache nginx
WORKDIR /app
RUN mkdir -p /app/config /app/data

COPY --from=frontend-build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=backend-build /app /app

RUN npm install -g pnpm && pnpm install --production

VOLUME ["/app/config", "/app/data"]
EXPOSE 8008

COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh
ENTRYPOINT ["/app/docker-entrypoint.sh"]
