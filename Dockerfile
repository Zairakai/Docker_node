# ================
# BUILD ARGUMENTS - VERSIONS
# ================

# Build metadata
ARG IMAGE_VERSION=unknown
ARG GIT_COMMIT=unknown
ARG BUILD_DATE=unknown

ARG NODE_VERSION=22

# ================
# STAGE 0: BASE
# ================
FROM node:${NODE_VERSION}-alpine AS base

LABEL maintainer="Stanislas Poisson <stanislas.p@the-white-rabbits.com>" \
    org.opencontainers.image.source="https://gitlab.com/zairakai/dockers/node" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.description="Node.js 22 Alpine base image"

ARG IMAGE_VERSION
ARG GIT_COMMIT
ARG BUILD_DATE

ENV BUILD_STAGE=base \
    IMAGE_VERSION=${IMAGE_VERSION} \
    GIT_COMMIT=${GIT_COMMIT} \
    BUILD_DATE=${BUILD_DATE} \
    NODE_ENV=production \
    NPM_CONFIG_CACHE=/tmp/.npm \
    NPM_CONFIG_LOGLEVEL=warn \
    NODE_OPTIONS="--max-old-space-size=512"

EXPOSE 3000

RUN apk add --no-cache \
    bash \
    ca-certificates \
    tzdata \
    dumb-init \
  && mkdir -p /app /tmp/.npm \
  && chown -R node:node /app /tmp/.npm \
  && npm cache clean --force \
  && rm -rf /var/cache/apk/*

WORKDIR /app

COPY --chown=root:root scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=root:root scripts/healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

USER node

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["node"]

# ================
# STAGE 1: PRODUCTION
# ================
FROM base AS prod

LABEL stage="prod" \
    description="Production-ready Node.js 22"

ENV BUILD_STAGE=prod

COPY --chown=root:root config/prod/npm.conf /etc/npmrc
COPY --chown=root:root config/prod/node.prod.json /usr/local/etc/node-config.json

# ================
# STAGE 2: DEVELOPMENT
# ================
FROM base AS dev

LABEL stage="dev" \
    description="Development Node.js 22 with dev tools"

USER root

ENV BUILD_STAGE=dev \
    NODE_ENV=development \
    NPM_CONFIG_LOGLEVEL=info \
    NODE_OPTIONS="--max-old-space-size=1024 --inspect=0.0.0.0:9229" \
    CHOKIDAR_USEPOLLING=true

RUN apk add --no-cache \
    git \
    openssh-client \
    curl \
    unzip \
    build-base \
    python3 \
    make \
    g++ \
    vim \
    jq \
  && npm install -g \
    nodemon \
    pm2 \
    typescript \
    ts-node \
  && mkdir -p /home/node/.cache /home/node/.npm \
  && chown -R node:node /home/node \
  && npm cache clean --force

COPY --chown=root:root config/dev/node.dev.json /usr/local/etc/node-config.json
COPY --chown=root:root scripts/dev-setup.sh /usr/local/bin/dev-setup.sh
COPY --chown=root:root scripts/healthcheck-dev.sh /usr/local/bin/healthcheck-dev.sh

RUN chmod +x /usr/local/bin/dev-setup.sh /usr/local/bin/healthcheck-dev.sh

USER node

RUN /usr/local/bin/dev-setup.sh

HEALTHCHECK --interval=30s --timeout=15s --start-period=10s --retries=3 \
    CMD /usr/local/bin/healthcheck-dev.sh

EXPOSE 9229 24678

CMD ["npm", "run", "dev"]

# ================
# STAGE 3: TEST
# ================
FROM dev AS test

LABEL stage="test" \
    description="Test Node.js 22 with vitest and coverage"

USER root

ENV BUILD_STAGE=test \
    NODE_ENV=test \
    CI=true

RUN npm install -g \
    vitest \
    @vitest/coverage-v8 \
    c8 \
  && mkdir -p /home/node/test-results /home/node/coverage \
  && chown -R node:node /home/node \
  && npm cache clean --force

COPY --chown=root:root config/test/node.test.json /usr/local/etc/node-config.json
COPY --chown=root:root scripts/healthcheck-test.sh /usr/local/bin/healthcheck-test.sh

RUN chmod +x /usr/local/bin/healthcheck-test.sh

USER node

HEALTHCHECK --interval=30s --timeout=20s --start-period=15s --retries=3 \
    CMD /usr/local/bin/healthcheck-test.sh

CMD ["npm", "test"]
