# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .
RUN npm run build && npm prune --omit=dev

# Production stage
FROM node:22-alpine AS production

WORKDIR /app

ENV NODE_ENV=production

# ffmpeg is required to convert Loop's MP4 recordings to WebM before upload to MeetNote
RUN apk add --no-cache ffmpeg

COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

EXPOSE 8080

CMD ["node", "dist/main.js"]
