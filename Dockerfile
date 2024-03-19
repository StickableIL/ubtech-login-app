# ---- Base Node ----
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./

# ---- Dependencies ----
FROM base AS dependencies
RUN npm install --only=production
# Copy production node_modules aside
RUN cp -R node_modules prod_node_modules
# Install ALL node_modules, including 'devDependencies'
RUN npm install

# ---- Build ----
FROM dependencies AS build
COPY . .
RUN npm run build

# ---- Release ----
FROM base AS release
# Copy production node_modules
COPY --from=dependencies /app/prod_node_modules ./node_modules
# Copy app sources
COPY --from=build /app/build ./build
# Expose port
EXPOSE 3000
CMD ["npm", "start"]