# ============================================
# 前端构建阶段
# ============================================
FROM --platform=$BUILDPLATFORM node:18-alpine AS frontend-build
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 依赖安装（利用缓存层）
COPY frontend/package*.json frontend/pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# 复制源码并构建
COPY frontend/ ./
RUN pnpm run build

# ============================================
# 后端构建阶段
# ============================================
FROM --platform=$BUILDPLATFORM node:18-alpine AS backend-build
WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 依赖安装
COPY backend/package*.json backend/pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# 复制源码、清理开发数据库并构建
COPY backend/ ./
RUN rm -f database.sqlite && pnpm run build

# ============================================
# 生产环境镜像（ARMv7 目标平台）
# ============================================
FROM node:18-alpine

# 安装 Nginx 和必要工具
RUN apk add --no-cache nginx tini

# 设置工作目录
WORKDIR /app

# 创建配置和数据目录
RUN mkdir -p /app/config /app/data /run/nginx

# 复制前端构建产物到 Nginx
COPY --from=frontend-build /app/dist /usr/share/nginx/html

# 复制 Nginx 配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 复制后端构建产物
COPY --from=backend-build /app/dist ./dist
COPY --from=backend-build /app/package*.json ./

# 安装生产环境依赖（使用 pnpm）
RUN npm install -g pnpm && \
    pnpm install --production --frozen-lockfile && \
    npm cache clean --force && \
    pnpm store prune

# 设置数据卷
VOLUME ["/app/config", "/app/data"]

# 暴露端口
EXPOSE 8008

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8008/health || exit 1

# 启动脚本
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# 使用 tini 作为 init 进程
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/app/docker-entrypoint.sh"]
