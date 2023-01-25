FROM bxffour/dlog-build:latest AS build
WORKDIR /go/src/dlog
COPY . .

RUN CGO_ENABLED=0 go build -o /go/bin/dlog ./cmd/dlog
RUN go install github.com/grpc-ecosystem/grpc-health-probe@latest

FROM alpine:3.17.1
COPY --from=build /go/bin/dlog /bin/dlog
COPY --from=build /go/bin/grpc-health-probe /bin/grpc-health-probe
ENTRYPOINT ["/bin/dlog"]
