FROM node:22-bookworm-slim AS node-runtime

FROM python:3.12-slim-bookworm

ARG DSH_VERSION=0.1.5-rc.1
ARG TELEGRAM_PLUGIN_VERSION=0.1.2

COPY --from=node-runtime /usr/local/bin/node /usr/local/bin/node
COPY --from=node-runtime /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && ln -s /usr/local/bin/python3 /usr/bin/python3 \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git zstd \
    && npm install --global "@deepseek-ai/dsh@${DSH_VERSION}" "dsh-plugin-telegram@${TELEGRAM_PLUGIN_VERSION}" \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

COPY telegram-markdown.mjs \
  /usr/local/lib/node_modules/dsh-plugin-telegram/scripts/telegram-markdown.mjs

RUN sed -i "/from '.\\/agent.mjs'/a import { sendMarkdown } from './telegram-markdown.mjs'" \
      /usr/local/lib/node_modules/dsh-plugin-telegram/scripts/bot.mjs \
    && sed -i 's/await send(chatId, answer)/await sendMarkdown(chatId, answer, send)/' \
      /usr/local/lib/node_modules/dsh-plugin-telegram/scripts/bot.mjs

ENV DSH_HOME=/root/.dsh
ENV DSH_AGENTS_HOME=/root/.agents
ENV DSH_PROJECTS_DIR=/root/professor_ot/agent/projects
ENV DSH_SESSIONS_DIR=/root/.dsh/sessions
ENV DSH_TG_CLI_BIN=/usr/local/bin/dsh
ENV DSH_TG_PROFILE=headless
ENV DSH_TG_TIMEOUT_MIN=30

CMD ["dsh-tg-bot"]
