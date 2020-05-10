#This file is used to build a "builder" image for the image resizing app in this project.
#The node base image has to be a linux-x64 system, as testing will require to use linux-x64 binaries like Sharp.
#Using an alpine NodeJS image is therefore not possible.
FROM node:14.2.0-stretch

#Node images don't come with zip installed. zip is required to build the app's package to be deployed using AWS Lambdas.
RUN apt update && apt install zip