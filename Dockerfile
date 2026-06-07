# ================= 阶段 1: 依赖安装与前端构建 =================
FROM --platform=$BUILDPLATFORM node:18-alpine AS builder

WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制依赖定义文件
COPY package*.json pnpm-lock.yaml* pnpm-workspace.yaml* ./
COPY frontend/package*.json ./frontend/
COPY backend/package*.json ./backend/

# 安装所有依赖
RUN pnpm install --frozen-lockfile

# 复制所有源码
COPY . .

# 执行前端构建 (根据你的 README: pnpm build:frontend)
RUN pnpm build:frontend

# 执行后端构建 (根据你的 README: cd backend && pnpm build)
RUN cd backend && pnpm build

# 清理缓存和开发依赖，只保留后端生产环境必需的依赖
RUN rm -rf node_modules && rm -f backend/database.sqlite
RUN pnpm install --prod --frozen-lockfile

# ================= 阶段 2: 最终生产环境镜像 (目标 ARMv7) =================
FROM node:18-alpine

# 安装 Nginx
RUN apk add --no-cache nginx

# 设置工作目录
WORKDIR /app

# 创建配置和数据目录
RUN mkdir -p /app/config /app/data

# 1. 复制前端构建产物到 Nginx 静态目录
COPY --from=builder /app/frontend/dist /usr/share/nginx/html

# 2. 复制 Nginx 配置文件 (请确保项目根目录下有 nginx.conf)
COPY nginx.conf /etc/nginx/nginx.conf

# 3. 复制后端构建产物及生产环境依赖
COPY --from=builder /app/backend /app/backend
COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/package.json /app/package.json

# 设置数据卷
VOLUME ["/app/config", "/app/data"]

# 暴露端口
EXPOSE 8008

# 启动脚本 (请确保项目根目录下有 docker-entrypoint.sh)
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# 启动服务
ENTRYPOINT ["/app/docker-entrypoint.sh"]
