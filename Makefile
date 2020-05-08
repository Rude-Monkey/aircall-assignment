build: clean
	docker run --rm -v ${PWD}/sre-hiring-test:/tmp -w /tmp node:14.2.0-stretch /bin/bash -c "npm install && apt update && apt install zip && zip -r resize.zip ."

clean:
	rm sre-hiring-test/resize.zip || true
