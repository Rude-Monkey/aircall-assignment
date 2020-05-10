all: builder test build tf

build: 
	docker run --rm -v ${PWD}/src:/tmp -w /tmp resize-lambda-builder:latest /bin/sh -c "npm install && zip -r resize.zip ."

builder: 
	docker build -t resize-lambda-builder:latest .

clean:
	rm src/resize.zip || true

deprecated-build: clean
	docker run --rm -v ${PWD}/src:/tmp -w /tmp node:14.2.0-stretch /bin/bash -c "npm install && apt update && apt install zip && zip -r resize.zip ."

destroy:
	terraform destroy -auto-approve
	rm terraform.*      
	rm -r .terraform

test:
	docker run --rm -v ${PWD}/src:/tmp -w /tmp resize-lambda-builder:latest /bin/sh -c "npm install && npm test"

tf: 
	terraform apply -auto-approve || terraform init && terraform apply -auto-approve