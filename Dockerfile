# ============================================
# 前端构建阶段
# ============================================
FROM --platform=$BUILDPLATFORM node:18-alpine AS frontend-build
WORKDIR /app

RUN npm install -g pnpm

COPY frontend/package*.json ./
RUN pnpm install

COPY frontend/ ./
RUN npm run build

# ============================================
# 后端构建阶段
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

# 安装 Nginx
RUN apk add --no-cache nginx

# 设置工作目录
WORKDIR /app

# 创建配置和数据目录
RUN mkdir -p /app/config /app/data

# 复制前端构建产物到 Nginx
COPY --from=frontend-build /app/dist /usr/share/nginx/html

# 复制 Nginx 配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 复制后端构建产物到生产环境镜像
COPY --from=backend-build /app /app

# 安装生产环境依赖（使用 pnpm）
RUN npm install -g pnpm && pnpm install --production

# 设置数据卷
VOLUME ["/app/config", "/app/data"]

# 暴露端口
EXPOSE 8008

# 启动脚本
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# 启动服务
ENTRYPOINT ["/app/docker-entrypoint.sh"]
