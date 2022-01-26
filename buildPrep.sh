#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
set -e -x

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/root/go/bin
rm -f go1.17.6.linux-amd64.tar*
: "${GOPATH:=$HOME/go}"

if which git ; then
  echo "git is installed."
else
  echo "git wasn't installed, trying to install"
  yum install -y git
fi


if which go ; then
  echo "Go is installed."
else
  echo "Go wasn't installed, trying to install"
  wget https://dl.google.com/go/go1.17.6.linux-amd64.tar.gz
  tar -C /usr/local -xzf go1.17.6.linux-amd64.tar.gz
fi

GO_VERSION="1.17.6"
INSTALLED_GO_VERSION=$(go version | awk '{print $3}')

if [[ "go${GO_VERSION}" !=  $INSTALLED_GO_VERSION ]]; then
    echo "Attempting to switch go from version ${INSTALLED_GO_VERSION} to ${GO_VERSION}"
    go get golang.org/dl/go$GO_VERSION || true
    $GOPATH/bin/go$GO_VERSION download || true
    GO_EXEC=$(which go)
fi

mkdir -p $GOPATH/bin
mkdir -p $GOPATH/src
mkdir -p $GOPATH/pkg

if which dep; then
  echo "dep is installed."
else
  echo "dep wasn't installed, trying to install"
  curl https://raw.githubusercontent.com/golang/dep/master/install.sh | DEP_RELEASE_TAG=v0.5.0 sh
fi

ORIGINAL_DIR=$PWD
mkdir -p $GOPATH/src/github.com/zalando/${BINARY}
cp -r ./[!\.]* $GOPATH/src/github.com/zalando/${BINARY}

if [ "$BINARY" == "postgres-operator-ui" ]; then
  cd ui
  make clean
  make docker
else
  make deps
  make clean
  make docker
fi

cd $GOPATH/src/github.com/zalando/${BINARY}
