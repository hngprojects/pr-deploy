# Dockerfile
FROM node:14

WORKDIR /app

COPY package.json .
RUN npm installj

COPY . .

CMD [ "sh", "-c", "node server.js" ]
