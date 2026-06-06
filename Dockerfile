# syntax=docker/dockerfile:1

############################
# 前端构建
############################
FROM --platform=$BUILDPLATFORM node:20-bookworm-slim AS frontend-build

WORKDIR /app

RUN npm install -g pnpm

COPY package.json ./
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./

COPY frontend/package.json ./frontend/

RUN pnpm install --no-frozen-lockfile

COPY frontend ./frontend

# 解决 vite-plugin-pwa / crypto 问题
ENV BUILD_PWA=false

RUN pnpm --filter cloud-saver-web build


############################
# 后端构建
############################
FROM --platform=$BUILDPLATFORM node:20-bookworm-slim AS backend-build

WORKDIR /app

RUN npm install -g pnpm

COPY package.json ./
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./

COPY backend/package.json ./backend/

RUN pnpm install --no-frozen-lockfile

COPY backend ./backend

RUN pnpm --filter cloud-saver-server build


############################
# 运行环境（ARMv7）
############################
FROM node:20-bookworm-slim

RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mkdir -p /app/config /app/data

############################
# 前端静态文件
############################
COPY --from=frontend-build /app/frontend/dist /usr/share/nginx/html

############################
# 后端代码
############################
COPY --from=backend-build /app/backend /app

############################
# nginx 配置
############################
COPY nginx.conf /etc/nginx/nginx.conf

############################
# 生产依赖（关键修复 sqlite3 / bcrypt）
############################
RUN npm install -g pnpm

COPY package.json ./
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./
COPY backend/package.json ./backend/

RUN pnpm install --prod --filter cloud-saver-server --no-frozen-lockfile

############################
# 启动脚本
############################
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

VOLUME ["/app/config", "/app/data"]

EXPOSE 8008

ENTRYPOINT ["/app/docker-entrypoint.sh"]
