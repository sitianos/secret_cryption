#! /bin/bash

function check_existence () {
    if [ -f "$1" ]; then
        echo "$1 already exists"
        echo -n "Remove $1? [y/^y] "
        read RM
        if [ $RM == y ]; then
            shred -u "$1"
        else
            exit 1
        fi
    fi
}

ARGS=()

while [ "$1" != "" ]; do
    case $1 in
        -h) echo "./genkey.sh <private key> <public key>"; exit 1;;
        *) ARGS+=($1); shift;;
    esac
done

if [ ${#ARGS[@]} != 2 ]; then
    echo "required 2 values private key and public key"
    exit 1
fi

PRIVKEY=${ARGS[0]}
PUBKEY=${ARGS[1]}


check_existence ${PRIVKEY}
check_existence ${PUBKEY}
tempkey=$(mktemp -p .)
openssl genpkey -algorithm RSA  -out "${tempkey}" -pkeyopt rsa_keygen_bits:3072
#openssl genrsa -out $1 -aes256 3072
openssl pkey -in "${tempkey}" -aes-256-cbc -out ${PRIVKEY} && \
openssl pkey -in "${tempkey}" -pubout -out ${PUBKEY}
chmod 600 ${PRIVKEY}
shred -u ${tempkey}
