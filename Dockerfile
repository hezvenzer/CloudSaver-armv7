# syntax=docker/dockerfile:1

############################
# 前端构建（Vite + Vue + PWA）
############################
FROM --platform=$BUILDPLATFORM node:20-alpine AS frontend-build

WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 workspace 基础文件
COPY package.json ./
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./

# 只复制前端 package（加速依赖安装）
COPY frontend/package.json ./frontend/

# 安装依赖
RUN pnpm install --no-frozen-lockfile

# 复制前端源码
COPY frontend ./frontend

# 🚨 关键：禁用 PWA（解决 crypto / terser / workbox 报错）
ENV BUILD_PWA=false

# 构建前端
RUN pnpm --filter cloud-saver-web build


############################
# 后端构建（TypeScript）
############################
FROM --platform=$BUILDPLATFORM node:20-alpine AS backend-build

WORKDIR /app

RUN npm install -g pnpm

COPY package.json ./
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./

COPY backend/package.json ./backend/

RUN pnpm install --no-frozen-lockfile

COPY backend ./backend

# 编译后端 TS
RUN pnpm --filter cloud-saver-server build


############################
# 生产运行环境
############################
FROM node:20-alpine

# 安装 nginx
RUN apk add --no-cache nginx

WORKDIR /app

# 创建运行目录
RUN mkdir -p /app/config /app/data

# 前端静态文件
COPY --from=frontend-build /app/frontend/dist /usr/share/nginx/html

# 后端构建产物
COPY --from=backend-build /app/backend /app

# nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 安装 pnpm（运行时依赖）
RUN npm install -g pnpm

# 安装生产依赖（只装后端）
COPY package.json ./
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./
COPY backend/package.json ./backend/

RUN pnpm install --prod --filter cloud-saver-server --no-frozen-lockfile

# 启动脚本
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# 数据卷
VOLUME ["/app/config", "/app/data"]

EXPOSE 8008

ENTRYPOINT ["/app/docker-entrypoint.sh"]
