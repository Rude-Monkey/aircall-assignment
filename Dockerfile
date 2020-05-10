FROM node:14.2.0-alpine

RUN apk add zip

ENTRYPOINT [ "/bin/sh", "-c", "npm install && zip -r resize.zip ." ]
# CMD [ "resize.zip", "." ]