FROM postgres:12-alpine

ENV POSTGIS_VERSION 3.0.1

RUN CONFIG="\
    " \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    # && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        g++ \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
        clang-dev \
        protobuf-c-dev \
        llvm9-dev \
    \
    && apk add --no-cache --virtual .build-deps-testing \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        gdal-dev \
        geos-dev \
        proj-dev \
        protobuf-c-dev \
    && cd /usr/src/postgis \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure ${CONFIG}\
    && make \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && apk add --no-cache --virtual .postgis-rundeps-testing \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        geos \
        gdal \
        proj \
        protobuf-c \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps .build-deps-testing


COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
COPY ./update-postgis.sh /usr/local/bin
