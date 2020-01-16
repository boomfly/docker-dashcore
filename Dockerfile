FROM node:8-slim as builder

RUN apt-get update && apt-get install -y curl build-essential libzmq3-dev python
WORKDIR /usr/app
RUN npm init -y && npm i --save @dashevo/dashcore-lib @dashevo/dashcore-node @dashevo/insight-api @dashevo/insight-ui
RUN sed -i -e "s/var dashcore/Object.defineProperty(global, '_dashcore', { get(){ return undefined }, set(){} });\nvar dashcore/g" /usr/app/node_modules/@dashevo/dashcore-node/bin/dashcore-node

ADD https://github.com/dashpay/dash/releases/download/v0.14.0.5/dashcore-0.14.0.5-x86_64-linux-gnu.tar.gz /tmp/
RUN tar -xvf /tmp/dashcore-*.tar.gz -C /tmp/

# Actual image
FROM node:8-slim

LABEL maintainer="boomfly@rambler.ru"
LABEL description="dashcore image"

RUN apt-get update && apt-get install -y libzmq3-dev

COPY --from=builder /usr/app /usr/app/
COPY --from=builder /tmp/dashcore*/bin/*  /usr/local/bin/
COPY ./dashcore-node.json /usr/app/dashcore-node.json

RUN chmod a+x /usr/local/bin/*

WORKDIR /usr/app
VOLUME ["/.dashcore/data"]
EXPOSE 3001

CMD ["/usr/app/node_modules/@dashevo/dashcore-node/bin/dashcore-node", "start", "-c", "/usr/app"]
