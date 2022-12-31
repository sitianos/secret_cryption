#! /bin/bash

while [ "$1" != "" ]; do
    case $1 in
        -o) shift; out=$1;shift;;
        -k) shift; keys+=($1);shift;;
        -h) echo "encrypt.sh secretfile -k publickey [-o encryptedfile]"; exit 1;;
        *) secretfile=$1;shift;;
    esac
done

if [ -z "${secretfile}" ]; then
    echo "secret file is not specified"
    exit 1
fi

if [ ! -e "${secretfile}" ]; then
    echo "crypted file does not exist"
    exit 1
fi

if [ ${#keys[@]} = 0 ]; then
    echo "no public key is specified"
    exit 1
fi

for key in ${keys[@]}; do
    if [ ! -e ${key} ]; then
        echo "${key} does not exist"
        exit 1
    fi
done

if [ -z "${out}" ]; then
    out=${secretfile%.*}.tar.gz
fi

workdir=$(mktemp -d -p .)

echo "encrypted ${secretfile} to ${out} by ${key}"

# generate random text
randkey=$(mktemp -p .)
openssl rand -out "${randkey}" -base64 32
# sort "${secretfile}" -t ',' -k 2

# AES encrypt files with a random text
openssl enc -e -pbkdf2 -aes-256-cbc -in "${secretfile}" \
    -out "${workdir}/cipher.enc" -kfile "${randkey}" -base64
if [ $? -gt 0 ]; then
    echo "Error occured. unable to crypt secret file."
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
    cp "${keys[$i]}" "${slotdir}/$(basename ${keys[$i]})"
    if [ $? -gt 0 ]; then
        echo "Error occured. unable to crypt randkey with ${keys[$i]}"
        shred -u "${randkey}"
        rm -rf "${workdir}"
        exit 1
    fi
done

shred -u "${randkey}"
# compress an encrypted file and key slots
tar czf "${out}" -C "${workdir}" $(ls ${workdir})
rm -rf "${workdir}"

echo 'Encrypted. Create' ${out}
echo 'Remove' ${secretfile}? '[y/^y]'
read RM
if [ $RM == y ]; then
    shred -u "${secretfile}"
fi
