# for development only
FROM node:14-alpine

WORKDIR /src

COPY package.json /src

RUN yarn install

COPY . /src

CMD yarn dev
