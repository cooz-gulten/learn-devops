# This Dockerfile runs the helloworld server from
# https://grpc.io/docs/quickstart/go.html

FROM golang
RUN go get -u google.golang.org/grpc
RUN mkdir -p $GOPATH/src/google.golang.org/grpc/examples
WORKDIR $GOPATH/src/google.golang.org/grpc/examples
COPY examples/ ./
RUN go mod tidy

EXPOSE 50051
CMD ["go", "run", "helloworld/greeter_server/main.go"]