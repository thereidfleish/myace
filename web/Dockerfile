# for development only
FROM node:14-alpine

WORKDIR /src

COPY package.json /src

RUN npm install --silent

COPY . /src

CMD yarn start
