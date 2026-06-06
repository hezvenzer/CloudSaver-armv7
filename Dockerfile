FROM --platform=$BUILDPLATFORM node:20-alpine AS frontend-build

WORKDIR /app

COPY frontend/package.json ./
COPY frontend/pnpm-lock.yaml ./

RUN npm install -g pnpm
RUN pnpm install

COPY frontend/ ./

RUN pnpm run build


FROM --platform=$BUILDPLATFORM node:20-alpine AS backend-build

WORKDIR /app

COPY backend/package.json ./
COPY backend/pnpm-lock.yaml ./

RUN npm install -g pnpm
RUN pnpm install

COPY backend/ ./

RUN pnpm run build


FROM --platform=$TARGETPLATFORM node:20-alpine

RUN apk add --no-cache nginx

WORKDIR /app

COPY --from=frontend-build /app/dist /usr/share/nginx/html
COPY --from=backend-build /app /app

RUN npm install --production

EXPOSE 8008

ENTRYPOINT ["/app/docker-entrypoint.sh"]
