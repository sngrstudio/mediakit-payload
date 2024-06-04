# base
FROM node:18.12-bullseye as base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# base for builders
FROM base AS builder-base
WORKDIR /usr/src/app
COPY package.json pnpm-lock.yaml ./

# prod deps installer
FROM builder-base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

# builder
FROM builder-base AS builder
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build

# runtime
FROM node:18.12-bullseye-slim as runtime
RUN apt update && apt install -y --no-install-recommends dumb-init

ENV NODE_ENV=production
ENV PAYLOAD_CONFIG_PATH=dist/payload.config.js

WORKDIR /usr/src/app
COPY --chown=node:node --from=prod-deps /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=builder /usr/src/app/dist ./dist
COPY --chown=node:node --from=builder /usr/src/app/build ./build
COPY --chown=node:node package.json pnpm-lock.yaml  ./

USER node
ENV HOST=0.0.0.0
ENV PORT=3000
EXPOSE 3000

CMD ["dumb-init", "node", "dist/server.js"]
