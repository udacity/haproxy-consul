#!/usr/bin/env sh
set -ex
cd /tmp
apk update

HAPROXY_VERSION=1.8.14
HAPROXY_MAJOR_VERSION=${HAPROXY_VERSION:0:3}
HAPROXY_SHA256=b17e402578be85e58af7a3eac99b1f675953bea9f67af2e964cf8bdbd1bd3fdf
LIBSLZ_VERSION=v1.1.0
LIBSLZ_SHA256=93073cbb68b3b77fb4289c3f5550ff466b4e10679fb3ac12bb7d5fe157c42498
BUILD_DEPS="make gcc g++ linux-headers python pcre-dev openssl-dev lua5.3-dev"
RUN_DEPS="pcre libssl1.0 musl libcrypto1.0 busybox lua5.3-libs"

# install build dependencies
apk add --virtual build-dependencies ${BUILD_DEPS}

# Compile libslz
curl -L -o libslz-${LIBSLZ_VERSION}.tar.gz "http://git.1wt.eu/web?p=libslz.git;a=snapshot;h=${LIBSLZ_VERSION};sf=tgz"
if [ "$(sha256sum libslz-${LIBSLZ_VERSION}.tar.gz | cut -f1 -d\ )" != "${LIBSLZ_SHA256}" ]; then
    (>2 echo "sha256sum does not match!")
    exit 1
fi
tar -xvf libslz-${LIBSLZ_VERSION}.tar.gz
make -C libslz static

# fetch haproxy
curl -L -o haproxy-${HAPROXY_VERSION}.tar.gz "http://www.haproxy.org/download/${HAPROXY_MAJOR_VERSION}/src/haproxy-${HAPROXY_VERSION}.tar.gz"
if [ "$(sha256sum haproxy-${HAPROXY_VERSION}.tar.gz | cut -f1 -d\ )" != "${HAPROXY_SHA256}" ]; then
    (>2 echo "sha256sum does not match!")
    exit 1
fi
tar -xzf haproxy-${HAPROXY_VERSION}.tar.gz
cd haproxy-${HAPROXY_VERSION}

# build haproxy
make PREFIX=/usr TARGET=linux2628 USE_PCRE=1 USE_PCRE_JIT=1 USE_OPENSSL=1 \
    USE_SLZ=1 SLZ_INC=../libslz/src SLZ_LIB=../libslz \
	USE_LUA=1 LUA_LIB=/usr/lib/lua5.3/ LUA_INC=/usr/include/lua5.3 \
    DEBUG=-g

# install
make PREFIX=/usr install-bin

# remove build dependencies
apk del build-dependencies

# install run dependencies
apk add ${RUN_DEPS}

# clean
cd -
rm -rf /tmp/*
rm -rf /var/cache/apk/*
