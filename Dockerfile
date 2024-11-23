# syntax=docker/dockerfile:1.4

FROM node:20.18-alpine AS base

RUN apk add --no-cache \
    python3 \
    make \
    g++ && \
    ln -sf /usr/bin/python3 /usr/bin/python

WORKDIR /app

FROM base AS prod-deps

COPY package.json ./
RUN --mount=type=cache,id=npm,target=/root/.npm npm install --omit=dev

FROM base AS builder

COPY package.json ./
RUN --mount=type=cache,id=npm,target=/root/.npm npm install
COPY . .
# Remove postBuild script since it's not found
RUN sed -i 's/\&\& node src\/scripts\/postBuild.js//' package.json && \
    npm run build

FROM base

COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=builder /app/.medusa ./
COPY --from=builder /app/package.json ./
COPY --from=builder /app/medusa-config.js ./

EXPOSE 9000 7001

CMD ["sh", "-c", "npx medusa db:setup --db medusa-talha-medusa-ogreniyor && npm run start:prod"]
