#!/bin/bash
echo "Generating RSA keys..."
mkdir -p keys; cd keys
openssl genrsa -out private_key.pem 2048 2>/dev/null
openssl rsa -in private_key.pem -pubout -out public_key.pem 2>/dev/null
openssl rsa -in private_key.pem -pubout -outform DER -out public_key.der 2>/dev/null
chmod 600 private_key.pem; chmod 644 public_key.pem public_key.der
echo "✓ Keys generated:"; ls -lh
