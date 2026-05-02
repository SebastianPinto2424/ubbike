FROM node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY src ./src
COPY tsconfig.json ./
RUN npm run build

FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=deps --chown=node:node /app/dist ./dist

USER node

EXPOSE 3000

CMD ["node", "dist/servidor.js"]
