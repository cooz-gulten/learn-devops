build_helloworld:
	docker build -t afandy/grpc-example-helloworld:latest . -f helloworld.Dockerfile
	docker push afandy/grpc-example-helloworld:latest

build_routeguide:
	docker build -t afandy/grpc-example-routeguide:latest . -f routeguide.Dockerfile
	docker push afandy/grpc-example-routeguide:latest

build_gateway:
	docker build -t afandy/grpc-example-gateway:latest . -f grpclb.Dockerfile
	docker push afandy/grpc-example-gateway:latest

gen_key:
	openssl req -newkey rsa:4096 -nodes -keyout ssl/private/grpc.example.com.key -x509 -days 365 -out ssl/certs/grpc.example.com.crt

app_lb:
	oc new-app --docker-image=afandy/grpc-example-gateway:latest --name=grpc-gateway

app_rg1:
	oc new-app --docker-image=afandy/grpc-example-routeguide:latest --name=rg1

app_hw1:
	oc new-app --docker-image=afandy/grpc-example-helloworld:latest --name=hw1