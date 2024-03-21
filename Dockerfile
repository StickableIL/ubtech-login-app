# Use the official Node.js image as the base image
FROM node:14

# Set the working directory in the container
WORKDIR /app

# Copy the package.json and package-lock.json files to the container
COPY package*.json ./

# Install the server dependencies
RUN npm install

# Create the server directory
RUN mkdir -p server

# Copy the server code to the container
COPY server/server.js ./server/

# Change to the client directory
WORKDIR /app/client

# Copy the client's package.json and package-lock.json files to the container
COPY client/package*.json ./

# Install the client dependencies
RUN npm install

# Copy the client code to the container
COPY client/ .

# Change back to the root directory
WORKDIR /app

# Build the client app
RUN npm run build --prefix client

# Expose the port on which the server will run
EXPOSE 80

# Start the server
CMD ["node", "server/server.js"]