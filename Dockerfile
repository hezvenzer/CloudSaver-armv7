# syntax=docker/dockerfile:1

############################
# 1. 构建前端
############################
FROM node:18-alpine AS frontend-build

WORKDIR /app

RUN npm install -g pnpm

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY frontend ./frontend

RUN pnpm install
RUN pnpm --filter cloud-saver-web build


############################
# 2. 构建后端
############################
FROM node:18-alpine AS backend-build

WORKDIR /app

RUN npm install -g pnpm

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY backend ./backend

RUN pnpm install
RUN pnpm --filter cloud-saver-server build


############################
# 3. 运行环境（最干净）
############################
FROM node:18-alpine

RUN apk add --no-cache nginx

WORKDIR /app

RUN mkdir -p /app/config /app/data

############################
# 前端静态文件
############################
COPY --from=frontend-build /app/frontend/dist /usr/share/nginx/html

############################
# 后端运行产物（关键）
############################
COPY --from=backend-build /app/backend/dist /app/dist
COPY --from=backend-build /app/backend/package.json /app/package.json

############################
# 安装“运行依赖”（只装 express 等）
############################
RUN npm install -g pnpm \
 && pnpm install --prod

############################
# nginx
############################
COPY nginx.conf /etc/nginx/nginx.conf

############################
# 启动脚本
############################
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

EXPOSE 8008

ENTRYPOINT ["/app/docker-entrypoint.sh"]
