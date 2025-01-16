# Secret Cryption
Simple scripts for encrypting and decrypting secret files with multiple asymmetric keys

## Usage
Use `-h` option to show brief description of how to execute each command
### Generate key pair
example) To generate `privkey.pem` (private key) and `pubkey.pem` (public key), put the following command and enter passphrase for encrypting `privkey.pem`
```
./genkey privkey.pem pubkey.pem
# enter passphrase
```

### Encrypt secret files
example) To encrypt `secretfile` with public keys `pubkey.pem` and `pubkey2.pem` and create an encrypted archive file named `encfile`,
```
./encrypt secretfile -k pubkey.pem -k pubkey2.pem -o encfile
```

### Decypt secret files
example) To decrypt encrypted archive file `encfile` using private key `privkey.pem` which is corresponding to one of the public keys used in encryption and output it to file named `decfile`,
put the following command and enter passphrase for decrypting `privkey.pem`
```
./decrypt encfile -k privkey.pem -o decfile
# enter passphrase 
```
