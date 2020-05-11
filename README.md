# Aircall assignment

This project aims to build and deploy Aircall's [SRE hiring test](https://github.com/aircall/sre-hiring-test) on AWS using Lambdas.

## Prerequisites

You will need the following tools for this to work on your machine: 
- Terraform (tested with v0.12.24)
- Docker (tested with Docker version 18.09.2, build 6247962)

You will also need to give Terraform some way of using the AWS APIs. You can refer to the [AWS provider page](https://www.terraform.io/docs/providers/aws/index.html) from Terraform's documentation for that.

I chose to create a user in my AWS account with API access and gave it the following permissions (by affecting it to a group that had those permissions): 
- AWSLambdaFullAccess
- IAMFullAccess
- AmazonS3FullAccess
- CloudWatchLogsFullAccess
- AmazonAPIGatewayAdministrator

This will allow us to deploy all the required resources on AWS. *FullAccess permissions probably aren't necessary, in the way that they probably contain more permissions than what is actually required. Further hardening would probably be useful for a production grade deployment.

## Project structure

The goal here is to deploy a function to AWS Lambda and trigger that Lambda's execution when sending a POST request to an API (that will be created using AWS APIGateway). This function will take an image it is sent, manipulate it and store it to an AWS S3 Bucket.

![diagram](./misc/aircall-assignment-diagram.png)

This project contains: 
- A Terraform file with a Terraform module containing the files required to create the required AWS resources (Lambda function and IAM role, S3 bucket and APIGateway REST API with IAM role and Lambda integration).
- The JS app's source code and [documentation](./src/README.md) in the `src` directory.
- A Makefile with instructions to automate various steps (such as building & packaging the app, deploying it or destroying & cleaning the infrastructure).
- A Dockerfile that is used to provide the user with a builder image called `resize-lambda-builder`. This image can then be used to either run tests for the JS project or package it in a zip file so that it can be deployed to Lambda.
- An `images` directory containing a set of images used to make sure everything was correctly deployed. (I do not own rights to these pictures. They were either taken from [Unsplash](https://unsplash.com/) or using Google Images and making sure the images' licenses allowed them to be reused).

## Usage

### Deploy the infrastructure

To get everything started, simply run the following command: 
```
make all
```

This will first build the afformentioned builder image, then run tests and package the app in a zip file before deploying all the infrastructure to AWS.  

Everything going well, you will then be given two output values: `api_url` and `bucket_url`.  

It is also possible to only deploy the infrastructure on AWS by running `terraform apply -auto-approve` or `make tf`.

### Deleting the infrastructure

To remove every resource deployed for this project from your AWS account, simply run the following: 
```
make destroy
```

### Sending requests to the API

To send requests, you will need the `api_url` returned by Terraform.
```
curl --location --request POST '<api_url>' --form 'file=@file.jpg' --form 's3Key=file.jpg'
```

### Accessing the images

The app will store the modified images to an S3 bucket. This project deploys an S3 bucket with a `public-read` ACL, that allows anyone to get the files stored on it. You will therefore need to make sure the bucket's name is unique for it to be correctly created.  

The image files can be accessed using the `bucket_url` provided by the Terraform output using a browser or by running: 
```
curl <bucket_url>/file.jpg | file.jpg
```

For a given file (say `file.jpg`), the lambda function will store 3 files in the S3 bucket: 
- `file.jpg`
- `file.jpg_200`
- `file.jpg_75`

## Implementation choices

This section discusses aspects of the [initial requirements](./misc/README.md) that led to implementation decisions.

### S3 Bucket

AWS S3 is the targeted storage backend for the service. As I wanted people to be able to access the images that would be stored on my S3 bucket, I put a `public-read` ACL on it. This probably wouldn't be enough for a production setup (I guess it actually depends on what these images are meant for), but it allowed me to make sure anyone could use a demo version of the service and access their images on the S3 bucket.

### Using Lambdas

AWS Lambda provides its users with a fairly easy way to deploy individual functions without worrying (too much) about the underlying infrastructure. The intern that wrote the code clearly designed it with Lambda as a deployment target by exporting a handler and parsing incoming events.  

In order to allow a Lambda to store objects on S3, an IAM role with a policy giving access to `s3:PutObject` and `s3:PutObjectAcl` was added.

### AWS API Gateway

The API Gateway provides an easy way to create REST APIs. It is easy to add new paths and methods to an API using API resources and the user can also easily create various integrations. The `AWS_PROXY` integration type allows us to trigger a Lambda function and proxy the request body to it.

### Infrastructure as code

The requirements stated that the project owner wanted a "cool way" to deploy the project using an infrastructure as code tool.

I chose Terraform over tools like Ansible because of its declarative approach (instead of Ansible's procedural approach). Also, I found the AWS provider integration to be fairly simple to use.

To not "pollute" the project's root directory, I put the .tf files in a module called resize_lambda that contains all the files to: 
- configure the API Gateway to trigger a Lambda function whenever it receives a POST request on its `/image` path.
- configure a Lambda function to run the app's code, giving it access to a S3 bucket.
- create the S3 bucket the Lambda function will send the modified pictures to and make it publicly readable.

### Logs & Metrics

Logs were enabled for both the app running in Lambda and the API Gateway by giving them permissions to access `CloudWatch Logs`. Logs for these services can therefore be found in the CloudWatch log journals. This is much simpler to set up than setting up a complete log collection and storage stack like ELK. Plus, I should have no problem staying under the AWS free tier limits.

As far as metrics go, giving the Lambda function access to CloudWatch enables us to access information like the number of invocations over time, or the Lambda's success rate. This allowed to set up basic metrics without modifying a single line of the app's code. Solutions like Prometheus could also be used, but would require to instrument the JavaScript code using a [client library](https://github.com/siimon/prom-client).

### Tracing

No tracing was enabled for this project. Tracing could be enabled by instrumenting the code so that it used the OpenTracing client library. We would then need to connect it to a tracing backend. Multiple solutions exist. [Jaeger](https://www.jaegertracing.io/) probably is the most popular open-source (and free-to-use) solution to do so.  

With the sole context of this project, tracing would be done by creating a span whenever the handler receives an event and propagating its context with every function call... but I guess in the case other services interact with our Lambda, extracting the SpanContect from incoming requests would probably be more useful. I found a resource that would probably be useful on Lightstep's [tech blog](https://lightstep.com/blog/monitoring-serverless-functions-using-opentracing/). (Lightstep is a commercial product that can be used as a tracing backend alternative to Jaeger)

### Authentication

No authentication was added to the API Gateway. I guess that in the case other services hosted on AWS were the only services to interact with the service, restricting access to the API to given IAM roles would be a valid option.

### Builder image

In order to run tests and package the application into a zip file, we needed a linux-x64 system with npm and zip installed.

I decided to go for a Docker image which could therefore be used as part as a CI/CD process (by making it the image used by job runners for example).
I could either go with an Ubuntu/Debian/... image that had zip preinstalled and add npm, or go with a node image (which came with npm) and install zip. I didn't put too much thinking into it, but if performance is very important we would have to make a decision based on the volume deltas between the two base images and between both zip and npm packages.

Sadly, because `Sharp` is a linux-x64 binary, we couldn't use an alpine version of the node base image.

The image was purposely left without any `ENTRYPOINT` or `CMD` so that we could easily use it for both testing and packaging stages.

### Testing

Testing wasn't (explicitely) mentioned in the requirements, but I figured the project's maintainer would eventually feel more comfortable having tests to ensure code quality. I added Mocha to the JS project so that we could write and run tests using `make test`. No tests were actually added though and that would have to be added to the TODO list.
