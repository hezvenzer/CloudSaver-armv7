FROM node:18-alpine

# 安装 Nginx 和编译工具（用于 sqlite3 原生模块编译）
RUN apk add --no-cache nginx python3 make g++ gcc

# 设置工作目录
WORKDIR /app

# 创建配置和数据目录
RUN mkdir -p /app/config /app/data

# 复制前端构建产物到 Nginx
COPY frontend/dist /usr/share/nginx/html

# 复制 Nginx 配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 复制后端代码
COPY backend/ /app/

# 安装 pnpm 并在 ARMv7 上重新安装依赖（编译 sqlite3）
RUN npm install -g pnpm && \
    pnpm install --production && \
    # 强制重新编译 sqlite3
    cd node_modules/.pnpm/sqlite3@*/node_modules/sqlite3 && \
    npx node-pre-gyp install --fallback-to-build --build-from-source || \
    npm rebuild sqlite3 --build-from-source

# 清理编译工具（减小镜像体积）
RUN apk del python3 make g++ gcc

# 设置数据卷
VOLUME ["/app/config", "/app/data"]

# 暴露端口
EXPOSE 8008

# 启动脚本
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# 启动服务
ENTRYPOINT ["/app/docker-entrypoint.sh"]
