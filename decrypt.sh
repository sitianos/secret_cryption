#! /bin/bash

while [ "$1" != "" ]; do
    case $1 in
        -h) echo "decrypt.sh archivefile -k keyfile [-o outfile]"; exit 1;;
        -o) shift; out=$1;shift;;
        -k) shift; key=$1;shift;;
        *) enc=$1;shift;;
    esac
done

if [ ! -f "${enc}" -o ! -f "${key}" ] ; then
    echo "arguments does not exist" >&2
    exit 1
fi

if [ -n "${out}" -a -f "${out}" ]; then
    echo "${out} already exists"
    echo -n "Replace ${out}? [y/^y] "
    read RM
    if [ $RM != y ]; then
        echo "Abort" >&1
        exit 1
    fi
fi

workdir=$(mktemp -d -p .)

tar xzf "${enc}" -C "${workdir}"
if [ $? -gt 0 ]; then
    echo "Error: failed to extract cipher files" >&2
   rm -rf ${workdir}
   exit 1
fi

# decrypt secret key with passphrase
deckey=$(mktemp -p .)
openssl pkey -in "${key}" -out "${deckey}"
if [ $? -gt 0 ]; then
    echo "Error: filed to unlock secret key" >&2
    rm -rf ${workdir} ${deckey}
    exit 1
fi

randkey=$(mktemp -p .)

# decrypt random key with secret key
for slotdir in ${workdir}/slots/*; do
#    if [[ $file =~ ^secrets/slot([0-9]+)/randkey.enc$ ]]; then
    # check if public key in slot matches private key
    cmp -s <(openssl pkey -text_pub -noout -in "${deckey}") <(openssl pkey -text_pub -noout -pubin -in "${slotdir}/pubkey") 2> /dev/null
    if [ $? = 0 ]; then
        echo "hit ${slotdir#${workdir}/}"
        slot=${slotdir}
        break
    fi
#    fi
done

if [ -z "${slot}" ]; then
    echo "Error: filed to find matching key slot" >&2
    shred -u ${randkey} ${deckey}
    rm -rf ${workdir}
    exit 1
fi

openssl pkeyutl -decrypt -inkey "${deckey}" -in "${slot}/randkey.enc" -out "${randkey}"

if [ $? != 0 ]; then
    echo "Error: failed to decrypt random key" >&2
    shred -u ${randkey} ${deckey}
    rm -rf ${workdir}
    exit 1
fi

# decrypt encrypted files with a random key
if [ -n "${out}" ]; then
    openssl enc -d -pbkdf2 -aes-256-cbc -in "${workdir}/cipher.enc" -kfile "${randkey}" -base64 -out "${out}"
else
    openssl enc -d -pbkdf2 -aes-256-cbc -in "${workdir}/cipher.enc" -kfile "${randkey}" -base64 # | column -s, -t
fi

if [ $? -gt 0 ]; then
    echo "Error: failed to decrypt ciphertext" >&2
    shred -u ${randkey} ${deckey}
    rm -rf ${workdir}
    exit 1
fi

echo "finish decryption"

shred -u ${randkey} ${deckey}
rm -rf ${workdir}
