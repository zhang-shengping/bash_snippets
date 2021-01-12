#!/bin/bash -e

source /home/heat-admin/pzhang/overcloudrc

SSL_DIR=/home/heat-admin/pzhang/tls/ssl
CA_CERT=pzhang_root
SERVER_CERT=pzhang_server
SERVER_SNI_CERT=pzhang_sni
CLIENT_CERT=pzhang_client
CLIENT_CRL=pzhang_client_crl

echo "basicConstraints=CA:TRUE" > ${SSL_DIR}/v3.ext

echo "Create CA certificate"
openssl genrsa -out ${CA_CERT}.key 1024
openssl req -new -key ${CA_CERT}.key -out ${CA_CERT}.csr -subj "/C=CN/ST=BJ/L=BJ/O=ABC/OU=IT/CN=rootca.com/emailAddress=ask@rootca.com"
openssl x509 -req -in ${CA_CERT}.csr -signkey ${CA_CERT}.key -out ${CA_CERT}.crt -extfile ${SSL_DIR}/v3.ext
openssl x509 -in ${CA_CERT}.crt -noout -text

echo "Create server certificate"
openssl genrsa -des3 -passout pass:1234 -out ${SERVER_CERT}.key 1024
openssl req -new -key ${SERVER_CERT}.key -passin pass:1234 -out ${SERVER_CERT}.csr -subj "/C=CN/ST=BJ/L=BJ/O=Example/OU=IT/CN=server.com/emailAddress=ask@server.com"
openssl x509 -req -in ${SERVER_CERT}.csr -out ${SERVER_CERT}.crt -CA ${CA_CERT}.crt -CAkey ${CA_CERT}.key -CAcreateserial
openssl verify -CAfile ${CA_CERT}.crt -verbose ${SERVER_CERT}.crt
openssl x509 -in ${SERVER_CERT}.crt -noout -text

echo "Create server SNI certificate"
openssl genrsa -des3 -passout pass:1234 -out ${SERVER_SNI_CERT}.key 1024
openssl req -new -key ${SERVER_SNI_CERT}.key -passin pass:1234 -out ${SERVER_SNI_CERT}.csr -subj "/C=CN/ST=BJ/L=BJ/O=Example/OU=IT/CN=server.com/emailAddress=ask@server.com"
openssl x509 -req -in ${SERVER_SNI_CERT}.csr -out ${SERVER_SNI_CERT}.crt -CA ${CA_CERT}.crt -CAkey ${CA_CERT}.key -CAcreateserial
openssl verify -CAfile ${CA_CERT}.crt -verbose ${SERVER_SNI_CERT}.crt
openssl x509 -in ${SERVER_SNI_CERT}.crt -noout -text

echo "Create client certificate"
openssl genrsa -des3 -passout pass:1234 -out ${CLIENT_CERT}.key 1024
openssl req -new -key ${CLIENT_CERT}.key -passin pass:1234 -out ${CLIENT_CERT}.csr -subj "/C=CN/ST=BJ/L=BJ/O=Example/OU=IT/CN=client.com/emailAddress=ask@client.com"
openssl x509 -req -in ${CLIENT_CERT}.csr -out ${CLIENT_CERT}.crt -CA ${CA_CERT}.crt -CAkey ${CA_CERT}.key -CAcreateserial
openssl verify -CAfile ${CA_CERT}.crt -verbose ${CLIENT_CERT}.crt
openssl x509 -in ${CLIENT_CERT}.crt -noout -text

touch ${SSL_DIR}/crl_index.txt
echo 00 > ${SSL_DIR}/crl_number

cat <<EOF > ${SSL_DIR}/crl_openssl.conf
# OpenSSL configuration for CRL generation
#
####################################################################
[ ca ]
default_ca	= CA_default		# The default ca section

####################################################################
[ CA_default ]
database = ${SSL_DIR}/crl_index.txt
crlnumber = ${SSL_DIR}/crl_number


default_days	= 365			# how long to certify for
default_crl_days= 30			# how long before next CRL
default_md	= default		# use public key default MD
preserve	= no			# keep passed DN ordering

####################################################################
[ crl_ext ]
# CRL extensions.
# Only issuerAltName and authorityKeyIdentifier make any sense in a CRL.
# issuerAltName=issuer:copy
authorityKeyIdentifier=keyid:always,issuer:always
EOF

openssl ca -config ${SSL_DIR}/crl_openssl.conf -gencrl -keyfile ${CA_CERT}.key -cert ${CA_CERT}.crt -out ${CLIENT_CRL}.pem

echo "create server container"
SERVER_CERT_REF=$(openstack secret store --secret-type=certificate --payload-content-type='text/plain' --name="${SERVER_CERT}.crt" --payload="$(cat ${SERVER_CERT}.crt)" | grep "Secret href" | awk '{ print $5 }')
SERVER_CERT_KEY_REF=$(openstack secret store --secret-type=private --payload-content-type='text/plain' --name="${SERVER_CERT}.key" --payload="$(cat ${SERVER_CERT}.key)" | grep "Secret href" | awk '{ print $5 }')
SERVER_CERT_KEYPASS_REF=$(openstack secret store --secret-type=passphrase --payload-content-type='text/plain' --name="${SERVER_CERT}.pass" --payload="1234" | grep "Secret href" | awk '{ print $5 }')
sleep 3
SERVER_CERT_CREF=$(openstack secret container create --name="${SERVER_CERT}.container" --type='certificate' \
  --secret="certificate=${SERVER_CERT_REF}" \
  --secret="private_key=${SERVER_CERT_KEY_REF}" \
  --secret="private_key_passphrase=${SERVER_CERT_KEYPASS_REF}" | grep "Container href" | awk '{ print $5 }')

echo "create client container"
SERVER_SNI_CERT_REF=$(openstack secret store --secret-type=certificate --payload-content-type='text/plain' --name="${SERVER_SNI_CERT}.crt" --payload="$(cat ${SERVER_SNI_CERT}.crt)" | grep "Secret href" | awk '{ print $5 }')
SERVER_SNI_CERT_KEY_REF=$(openstack secret store --secret-type=private --payload-content-type='text/plain' --name="${SERVER_SNI_CERT}.key" --payload="$(cat ${SERVER_SNI_CERT}.key)" | grep "Secret href" | awk '{ print $5 }')
SERVER_SNI_CERT_KEYPASS_REF=$(openstack secret store --secret-type=passphrase --payload-content-type='text/plain' --name="${SERVER_SNI_CERT}.pass" --payload="1234" | grep "Secret href" | awk '{ print $5 }')
SERVER_SNI_CERT_CREF=$(openstack secret container create --name="${SERVER_SNI_CERT}.container" --type='certificate' \
  --secret="certificate=${SERVER_SNI_CERT_REF}" \
  --secret="private_key=${SERVER_SNI_CERT_KEY_REF}" \
  --secret="private_key_passphrase=${SERVER_SNI_CERT_KEYPASS_REF}" | grep "Container href" | awk '{ print $5 }')

echo "create client ref"
CLIENT_CRL_REF=$(openstack secret store --secret-type=certificate --payload-content-type='text/plain' --name="${CLIENT_CRL}.pem" --payload="$(cat ${CLIENT_CRL}.pem)" | grep "Secret href" | awk '{ print $5 }')
CLIENT_CRL_CREF=$(openstack secret container create --name="${CLIENT_CRL}.container" --type='certificate' \
  --secret="certificate=${CLIENT_CRL_REF}" | grep "Container href" | awk '{ print $5 }')

echo "create ca container"
CA_CERT_REF=$(openstack secret store --secret-type=certificate --payload-content-type='text/plain' --name="${CA_CERT}.crt" --payload="$(cat ${CA_CERT}.crt)" | grep "Secret href" | awk '{ print $5 }')
CA_CERT_CREF=$(openstack secret container create --name="${CA_CERT}.container" --type='certificate' \
  --secret="certificate=${CA_CERT_REF}" | grep "Container href" | awk '{ print $5 }')

LB_NAME=pzhang_$(date +'%s')
LISTENER_NAME=pzhang_$(date +'%s')

echo "Create loadbalancer ${LB_NAME}"
neutron lbaas-loadbalancer-create $(neutron subnet-list | awk '/ vlan30_subnet / {print $2}') --name ${LB_NAME}

sleep 15

echo "Create listener ${LISTENER_NAME}"
neutron lbaas-listener-create --loadbalancer ${LB_NAME} --protocol-port 443 --protocol TERMINATED_HTTPS --name ${LISTENER_NAME} \
  --default-tls-container-ref=${SERVER_CERT_CREF} \
  --sni-container-refs=${SERVER_SNI_CERT_CREF} \
  --ca-container-id=${CA_CERT_CREF} \
  --mutual-authentication-up=True
