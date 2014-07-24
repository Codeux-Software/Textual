#!/bin/bash

CURRENT_DIRECTORY=`pwd`

OPENSSL_VERSION="1.0.0m"

cd /tmp

curl -O http://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz

tar -xvzf openssl-$OPENSSL_VERSION.tar.gz
mv openssl-$OPENSSL_VERSION openssl_x86_64

mkdir "openssl.sdk"

cd openssl_x86_64
./Configure darwin64-x86_64-cc --openssldir="/tmp/openssl.sdk" no-ssl2 no-ssl3
make
make install
