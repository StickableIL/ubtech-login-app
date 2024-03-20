FROM node:18-alpine AS build
WORKDIR /app
COPY package.json ./
RUN npm install
COPY server ./server
COPY client ./client
WORKDIR /app/client
RUN npm install
RUN npm run build