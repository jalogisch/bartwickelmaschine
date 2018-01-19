#!/usr/bin/env bash
#
# create certificates and sign them with the CA
# that is created with the create_ca.sh script
#
# The variable CRTNAME should be set with the needed/wanted certificate name.
# If needed additional alt_names should be set and the settings might be adjusted.
# 


CRTNAME="allssl.localdomain"


# Create folder for each key
mkdir /etc/myCA/${CRTNAME}

# create private key for server
openssl genrsa -out /etc/myCA/${CRTNAME}/${CRTNAME}.key 2048


# The following settings might be adjusted to your needs
cat >> /etc/myCA/${CRTNAME}/${CRTNAME}.cnf <<EOF
[ req ]
prompt = no
distinguished_name = req_distinguished_name

[ req_distinguished_name ]
C = DE
ST = NRW
L = Herne
O = Graylog Inc.
OU = Support
CN = ${CRTNAME}
emailAddress = hello@graylog.com
EOF


# create csr
openssl req -new -config /etc/myCA/${CRTNAME}/${CRTNAME}.cnf -key /etc/myCA/${CRTNAME}/${CRTNAME}.key -out /etc/myCA/${CRTNAME}/${CRTNAME}.csr

# create .ext file
#
# if additinonal alt_names are needed, just add them
# with the following number in sequence

cat << EOF > /etc/myCA/${CRTNAME}/${CRTNAME}.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${CRTNAME}
DNS.2 = localhost

EOF

# create the certificate
openssl x509 -req -in /etc/myCA/${CRTNAME}/${CRTNAME}.csr -CA /etc/myCA/myCA.pem -CAkey /etc/myCA/myCA.key -CAcreateserial \
-out /etc/myCA/${CRTNAME}/${CRTNAME}.crt -days 1825 -sha256 -extfile /etc/myCA/${CRTNAME}/${CRTNAME}.ext

# create certificate pem
cat /etc/myCA/${CRTNAME}/${CRTNAME}.crt /etc/myCA/${CRTNAME}/${CRTNAME}.key > /etc/myCA/${CRTNAME}/${CRTNAME}.pem

echo "created /etc/myCA/${CRTNAME} that contains all needed files"
echo ""
ls -la /etc/myCA/${CRTNAME}/