FROM arti.dev.cray.com/baseos-docker-master-local/alpine:3.12
MAINTAINER team-acid@zalando.de

EXPOSE 8081

RUN \
  apk add --no-cache \
    alpine-sdk \
    autoconf \
    automake \
    ca-certificates \
    libffi-dev \
    libtool \
    python3 \
    python3-dev \
    zlib-dev \
    && \
  python3 -m ensurepip && \
  rm -r /usr/lib/python*/ensurepip && \
  pip3 install --upgrade \
    gevent \
    jq \
    pip \
    setuptools \
    && \
  rm -rf \
    /root/.cache \
    /tmp/* \
    /var/cache/apk/*

COPY requirements.txt constraints.txt /
COPY start_server.sh /
RUN pip3 install -r /requirements.txt

COPY operator_ui /operator_ui

ARG VERSION=dev
RUN sed -i "s/__version__ = .*/__version__ = '${VERSION}'/" /operator_ui/__init__.py

WORKDIR /
CMD ["/usr/bin/python3", "-m", "operator_ui"]
