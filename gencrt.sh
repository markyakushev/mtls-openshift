#!/bin/bash  

NAMESPACE=mtls-test

# 1.Generate a new self-signed certificate
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -days 3650 -subj "/C=US/ST=California/L=Santa Cruz/O=TechCo/OU=Cloud/CN=microservice"

# 2.Get the OpenShift service-serving signing CA certificate and key
oc get secret signing-key -n  openshift-service-ca -o jsonpath="{.data['tls\.key']}" | base64 -d > ca.key
oc get secret signing-key -n  openshift-service-ca -o jsonpath="{.data['tls\.crt']}" | base64 -d > ca.crt

# 3.Sign the newly generated certificate with the OpenShift service-serving signing CA certificate
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -CAserial client.srl -out client.crt -sha256 -extfile client.ext 

# 4.Create a secret containing the certificate and the key
oc create secret tls microservice-client-cert --key="client.key" --cert="client.crt" -n ${NAMESPACE}

# 5.Cleanup
rm ca.key ca.crt client.key client.csr client.crt client.srl
