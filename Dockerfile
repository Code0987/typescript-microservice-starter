FROM node:10-alpine as build

# adds deps for node-gyp: remove if no native modules
RUN apk update && apk upgrade \
  && apk --no-cache add --virtual builds-deps build-base python

# set app basepath
ENV HOME=/home/app

# add app dependencies
COPY package.json $HOME/node/

# change workgin dir and install deps in quiet mode
WORKDIR $HOME/node
RUN npm install -q

# copy all app files
COPY . $HOME/node/

# compile typescript and build all production stuff
RUN npm run build

# remove dev dependencies that are not needed in production
RUN npm prune --production

# start new image for lower size
FROM node:10-alpine

# create use with no permissions
RUN addgroup -g 101 -S app && adduser -u 100 -S -G app -s /bin/false app

# set app basepath
ENV HOME=/home/app

# copy production complied node app to the new image
COPY --from=build $HOME/node/ $HOME/node/
RUN chown -R app:app $HOME/*

# run app with low permissions level user
USER app
WORKDIR $HOME/node

EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "./build"]
