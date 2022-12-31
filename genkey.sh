if [ $# -lt 2 ]; then
    echo required 2 values[private key,public key].
    exit 1
fi

tempkey=$(mktemp -p .)
openssl genpkey -algorithm RSA  -out "${tempkey}" -pkeyopt rsa_keygen_bits:3072
#openssl genrsa -out $1 -aes256 3072
openssl pkey -in "${tempkey}" -aes-256-cbc -out $1 && \
openssl pkey -in "${tempkey}" -pubout -out $2
chmod 600 $1
shred -u ${tempkey}
