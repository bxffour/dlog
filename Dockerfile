FROM golang:1.18.2-alpine3.15 AS build
WORKDIR /go/src/proglog
COPY . .

RUN CGO_ENABLED=0 go build -o /go/bin/proglog .
RUN go install github.com/grpc-ecosystem/grpc-health-probe@latest

FROM alpine:3.17.1
COPY --from=build /go/bin/proglog /bin/proglog
COPY --from=build /go/bin/grpc-health-probe /bin/grpc-health-probe
ENTRYPOINT ["/bin/proglog"]
