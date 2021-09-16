VERSION := $(shell yq e ".version" manifest.yaml)
VERSION_STRIPPED := $(shell echo $(VERSION) | sed -E 's/([0-9]+\.[0-9]+\.[0-9]+).*/\1/g')
MANAGER_SRC := $(shell find ./manager -name '*.rs') manager/Cargo.toml manager/Cargo.lock

.DELETE_ON_ERROR:

all: verify

clean: 
		rm monero.s9pk
		rm image.tar

monero.s9pk: manifest.yaml assets/compat/config_spec.yaml config_rules.yaml image.tar docs/instructions.md
		embassy-sdk pack
# 		embassy-sdk pack errors come from here, check your manifest, config, instructions, and icon

verify: monero.s9pk
		embassy-sdk verify monero.s9pk

install: monero.s9pk
		embassy-cli package install monero.s9pk

image.tar: Dockerfile docker_entrypoint.sh manager/target/aarch64-unknown-linux-musl/release/monerod-manager manifest.yaml
		DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/monerod/main:$(VERSION) --build-arg MONERO_VERSION=$(VERSION_STRIPPED) --build-arg N_PROC=$(shell nproc) --platform=linux/arm64 -o type=docker,dest=image.tar .

manager/target/aarch64-unknown-linux-musl/release/monerod-manager: $(MANAGER_SRC)
		docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/manager:/home/rust/src start9/rust-musl-cross:aarch64-musl cargo build --release
		docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/manager:/home/rust/src start9/rust-musl-cross:aarch64-musl musl-strip target/aarch64-unknown-linux-musl/release/monerod-manager