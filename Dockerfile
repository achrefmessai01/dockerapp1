FROM node:18-alpine
WORKDIR /usr/src/app

# Install production dependencies
COPY package*.json ./
# `npm ci` requires a package-lock.json. Use `npm install --omit=dev` which works
# with only package.json present and installs production deps.
RUN npm install --omit=dev

# Copy app
COPY . .

EXPOSE 80
CMD ["node", "index.js"]
