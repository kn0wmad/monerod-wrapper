# Multistage docker build, requires docker 17.05 or greater

# Build stage
FROM arm64v8/alpine:3.15 as builder

ARG MONERO_VERSION=release-v0.17.3

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk update
# RUN apk --no-cache add tini
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add boost \
		boost-atomic \
		boost-build \
		boost-build-doc \
		boost-chrono \
		boost-container \
		boost-context \
		boost-contract \
		boost-coroutine \
		boost-date_time \
		boost-dev \
		boost-doc \
		boost-fiber \
		boost-filesystem \
		boost-graph \
		boost-iostreams \
		boost-libs \
		boost-locale \
		boost-log \
		boost-log_setup \
		boost-math \
		boost-prg_exec_monitor \
		boost-program_options \
		boost-python3 \
		boost-random \
		boost-regex \
		boost-serialization \
		boost-stacktrace_basic \
		boost-stacktrace_noop \
		boost-static \
		boost-system \
		boost-thread \
		boost-timer \
		boost-type_erasure \
		boost-unit_test_framework \
		boost-wave \
		boost-wserialization
RUN apk --no-cache add bzip2
RUN apk --no-cache add ca-certificates
RUN apk --no-cache add cmake
RUN apk --no-cache add curl
RUN apk --no-cache add doxygen
RUN apk --no-cache add eudev-dev
RUN apk --no-cache add g++
RUN apk --no-cache add git
RUN apk --no-cache add gperf
RUN apk --no-cache add graphviz
RUN apk --no-cache add libexecinfo-dev
RUN apk --no-cache add libsodium-dev
RUN apk --no-cache add libtool
RUN apk --no-cache add libusb-dev
RUN apk --no-cache add linux-headers
RUN apk --no-cache add make
RUN apk --no-cache add miniupnpc-dev
RUN apk --no-cache add openssl-dev
RUN apk --no-cache add pkgconfig
RUN apk --no-cache add protobuf-dev
RUN apk --no-cache add readline-dev
RUN apk --no-cache add unbound-dev
RUN apk --no-cache add unzip
RUN apk --no-cache add libxslt
RUN apk --no-cache add zeromq-dev

# zmq.hpp
ARG CPPZMQ_VERSION=v4.4.1
ARG CPPZMQ_HASH=f5b36e563598d48fcc0d82e589d3596afef945ae
RUN set -ex \
	&& git clone --depth 1 -b ${CPPZMQ_VERSION} https://github.com/zeromq/cppzmq.git \
	&& cd cppzmq \
	&& test `git rev-parse HEAD` = ${CPPZMQ_HASH} || exit 1 \
	&& mkdir /usr/local/include \
	&& mv *.hpp /usr/local/include/

WORKDIR /usr/local

ARG NPROC
ENV CFLAGS='-fPIC'
ENV CXXFLAGS='-fPIC -DELPP_FEATURE_CRASH_LOG'

# Monero
ENV USE_SINGLE_BUILDDIR=1
ENV MONERO_VERSION=0.17.3.0
ENV MONERO_HASH=ab18fea3500841fc312630d49ed6840b3aedb34d
RUN set -ex \
	&& git clone https://github.com/monero-project/monero.git \
	&& cd monero \
	&& git checkout tags/v${MONERO_VERSION} \
	&& git submodule init \
	&& git submodule update \
	&& test `git rev-parse HEAD` = ${MONERO_HASH} || exit 1 \
	&& make -j16 release-static-linux-armv8

# Runtime stage
FROM arm64v8/alpine:3.15

RUN set -ex && apk add --update --no-cache \
		ca-certificates \
		libexecinfo \
		libsodium \
		ncurses-libs \
		pcsc-lite-libs \
		readline \
		zeromq

COPY --from=builder /usr/local/monero/build/release/bin/* /usr/local/bin/

# Contains the blockchain and wallet files
VOLUME /root/.bitmonero
WORKDIR /root/.bitmonero

ADD ./manager/target/aarch64-unknown-linux-musl/release/monerod-manager /usr/local/bin/monerod-manager
RUN chmod a+x /usr/local/bin/monerod-manager
ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh

EXPOSE 18080 18081

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
