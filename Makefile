CONFIG_PATH=${HOME}/.dlog/

.PHONY: init
init:
		mkdir -p ${CONFIG_PATH}

.PHONY: clean
clean:
		rm -rf ${CONFIG_PATH}

.PHONY: gencert
gencert:
		cfssl gencert \
				-initca test/ca-csr.json | cfssljson -bare ca

		cfssl gencert \
				-ca=ca.pem \
				-ca-key=ca-key.pem \
				-config=test/ca-config.json \
				-profile=server \
				test/server-csr.json | cfssljson -bare server

		cfssl gencert \
				-ca=ca.pem \
				-ca-key=ca-key.pem \
				-config=test/ca-config.json \
				-profile=client \
				-cn="root" \
				test/client-csr.json | cfssljson -bare root-client

		cfssl gencert \
				-ca=ca.pem \
				-ca-key=ca-key.pem \
				-config=test/ca-config.json \
				-profile=client \
				-cn="nobody" \
				test/client-csr.json | cfssljson -bare nobody-client

		mv *.pem *.csr ${CONFIG_PATH}

compile:
		protoc api/v1/*.proto \
			--go_out=. \
			--go-grpc_out=. \
			--go_opt=paths=source_relative \
			--go-grpc_opt=paths=source_relative \
			--proto_path=.

$(CONFIG_PATH)/model.conf:
		cp test/model.conf $@

$(CONFIG_PATH)/policy.csv:
		cp test/policy.csv $@

.PHONY: test
test: $(CONFIG_PATH)/policy.csv $(CONFIG_PATH)/model.conf
		gotest -race -v ./...

TAG ?= 0.0.1

build-docker:
	docker build -t sxntana/dlog:$(TAG) .