FROM node:18-alpine

# 安装 Nginx
RUN apk add --no-cache nginx

# 设置工作目录
WORKDIR /app

# 创建配置和数据目录
RUN mkdir -p /app/config /app/data

# 复制前端构建产物到 Nginx
COPY frontend/dist /usr/share/nginx/html

# 复制 Nginx 配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 复制后端代码并安装生产依赖
COPY backend/ /app/

# 安装生产环境依赖
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
