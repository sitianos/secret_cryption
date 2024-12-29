if [ $# -lt 2 ]; then
    echo "required 2 values [private key, public key]"
    exit 1
fi

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

check_existence $1
check_existence $2
tempkey=$(mktemp -p .)
openssl genpkey -algorithm RSA  -out "${tempkey}" -pkeyopt rsa_keygen_bits:3072
#openssl genrsa -out $1 -aes256 3072
openssl pkey -in "${tempkey}" -aes-256-cbc -out $1 && \
openssl pkey -in "${tempkey}" -pubout -out $2
chmod 600 $1
shred -u ${tempkey}
