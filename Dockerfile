# syntax=docker/dockerfile:1.4

FROM node:20.18.0-alpine AS base

RUN apk add --no-cache \
    python3 \
    make \
    g++ && \
    ln -sf /usr/bin/python3 /usr/bin/python

WORKDIR /app

FROM base AS prod-deps

COPY package.json package-lock.json ./
RUN --mount=type=cache,id=npm,target=/root/.npm npm ci --omit=dev

FROM base AS builder

COPY package.json package-lock.json ./
RUN --mount=type=cache,id=npm,target=/root/.npm npm ci
COPY . .
RUN npm run build

FROM base

COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=builder /app/.medusa ./
COPY --from=builder /app/tsconfig.json ./
COPY --from=builder /app/medusa-config.ts ./

WORKDIR /app/server

VOLUME ["/app/uploads", "/app/static"]

EXPOSE 9002

CMD ["npm", "run", "start:prod"]
