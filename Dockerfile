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
COPY --from=builder /app/medusa-config.ts ./
COPY --from=builder /app/tsconfig.json ./

# Create directories for uploads and static files
RUN mkdir -p /app/uploads /app/static

EXPOSE 9000 7001

ENV NODE_ENV=production
ENV BACKEND_URL=http://localhost:9000

CMD ["npm", "run", "start:prod"]