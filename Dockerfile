# Dockerfile
FROM node:14

WORKDIR /app

COPY package.json .
RUN npm installd

COPY . .

CMD [ "sh", "-c", "node server.js" ]
