#!/bin/bash -e

source /home/heat-admin/pzhang/overcloudrc

SSL_DIR=/home/heat-admin/pzhang/tls/ssl
TLS_DIR=/home/heat-admin/pzhang/tls

CA_CERT=pzhang_root
SERVER_CERT=pzhang_server
SERVER_SNI_CERT=pzhang_sni
CLIENT_CERT=pzhang_client
CLIENT_CRL=pzhang_client_crl

rm -rf ${TLS_DIR}/${CA_CERT}.key
rm -rf ${TLS_DIR}/${CA_CERT}.csr
rm -rf ${TLS_DIR}/${CA_CERT}.crt
rm -rf ${TLS_DIR}/${CA_CERT}.srl

rm -rf ${TLS_DIR}/${SERVER_CERT}.key 
rm -rf ${TLS_DIR}/${SERVER_CERT}.csr
rm -rf ${TLS_DIR}/${SERVER_CERT}.crt
 
rm -rf ${TLS_DIR}/${SERVER_SNI_CERT}.key 
rm -rf ${TLS_DIR}/${SERVER_SNI_CERT}.csr
rm -rf ${TLS_DIR}/${SERVER_SNI_CERT}.crt

rm -rf ${TLS_DIR}/${CLIENT_CERT}.key 
rm -rf ${TLS_DIR}/${CLIENT_CERT}.csr
rm -rf ${TLS_DIR}/${CLIENT_CERT}.crt

rm -rf ${TLS_DIR}/${CLIENT_CRL}.pem

rm -rf ${SSL_DIR}/*

secrets=($(openstack secret list -l 100 | grep pzhang | awk -F "|" '{print $2}'))
for i in ${!secrets[@]}; do
  openstack secret delete ${secrets[$i]}
done

containers=($(barbican secret container list -l 100 | grep pzhang | awk -F "|" '{print $2}'))
for x in ${!containers[@]}; do
  barbican secret container delete ${containers[$x]}
done

listeners=($(neutron lbaas-listener-list | grep pzhang | awk -F "|" '{print $2}'))
for lsr in ${!loadbalancers[@]}; do
  neutron lbaas-listener-delete ${loadbalancers[$lsr]}
done

sleep 10

loadbalancers=($(neutron lbaas-loadbalancer-list | grep pzhang | awk -F "|" '{print $2}'))
for lb in ${!loadbalancers[@]}; do
  neutron lbaas-loadbalancer-delete ${loadbalancers[$lb]}
done
