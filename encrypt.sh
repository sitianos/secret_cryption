#! /bin/bash

while [ "$1" != "" ]; do
    case $1 in
        -o) shift; out=$1;shift;;
        -k) shift; keys+=($1);shift;;
        -h) echo "encrypt.sh <secret file> [-k <public key>]... [-o <encrypted file>]"; exit 1;;
        *) secretfile=$1;shift;;
    esac
done

if [ -z "${secretfile}" ]; then
    echo "secret file is not specified" >&2
    exit 1
fi

if [ ! -e "${secretfile}" ]; then
    echo "crypted file does not exist" >&2
    exit 1
fi

if [ ${#keys[@]} = 0 ]; then
    echo "no public key is specified" >&2
    exit 1
fi

for key in ${keys[@]}; do
    if [ ! -e ${key} ]; then
        echo "${key} does not exist" >&2
        exit 1
    fi
done

if [ -z "${out}" ]; then
    out=${secretfile%.*}.tar.gz
fi

if [ -f "${out}" ]; then
    echo "${out} already exists"
    echo -n "Replace ${out}? [y/^y] "
    read RM
    if [ $RM != y ]; then
        echo "Abort" >&2
        exit 1
    fi
fi

workdir=$(mktemp -d -p .)

echo "Start encrypting ${secretfile} to ${out} by ${key}"

# generate random key
randkey=$(mktemp -p .)
openssl rand -out "${randkey}" -base64 32
# sort "${secretfile}" -t ',' -k 2

# AES encrypt files with random key
openssl enc -e -pbkdf2 -aes-256-cbc -in "${secretfile}" \
    -out "${workdir}/cipher.enc" -kfile "${randkey}" -base64
if [ $? -gt 0 ]; then
    echo "Error: failed to encrypt secret file" >&2
    shred -u "${randkey}"
    rm -rf "${workdir}"
    exit 1
fi

for ((i=0; i<${#keys[@]}; i++)) ; do
    slotdir=${workdir}/slots/${i}
    mkdir -p ${slotdir}
    # RSA encrypt a rand text with public keys
    openssl pkeyutl -encrypt -pubin -inkey "${keys[$i]}" \
        -in "${randkey}" -out "${slotdir}/randkey.enc" &&
    # cp "${keys[$i]}" "${slotdir}/$(basename ${keys[$i]})"
    cp "${keys[$i]}" "${slotdir}/pubkey"
    if [ $? -gt 0 ]; then
        echo "Error: failed to encrypt randkey with ${keys[$i]}" >&2
        shred -u "${randkey}"
        rm -rf "${workdir}"
        exit 1
    fi
done

shred -u "${randkey}"
# compress encrypted file and key slots
tar czf "${out}" -C "${workdir}" $(ls ${workdir})
echo "${out} is created"

rm -rf "${workdir}"
echo -n "Remove ${secretfile}? [y/^y] "
read RM
if [ $RM == y ]; then
    shred -u "${secretfile}"
fi
