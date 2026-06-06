# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM node:18-alpine as frontend-build
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install -g pnpm
RUN pnpm install
COPY frontend/ ./
RUN npm run build

FROM --platform=$BUILDPLATFORM node:18-alpine as backend-build
WORKDIR /app
COPY backend/package*.json ./
RUN npm install -g pnpm
RUN pnpm install
COPY backend/ ./
RUN rm -f database.sqlite
RUN npm run build

FROM node:18-alpine

RUN apk add --no-cache nginx

WORKDIR /app

RUN mkdir -p /app/config /app/data

COPY --from=frontend-build /app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=backend-build /app /app

RUN npm install --production

VOLUME ["/app/config", "/app/data"]

EXPOSE 8008

COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]
