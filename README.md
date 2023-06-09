# Mutual TLS with OpenShift service-serving certificates

OpenShift provides ability to secure communications using TSL and service-serving certificates.

https://docs.openshift.com/container-platform/4.12/security/certificates/service-serving-certificate.html

It is a very easy way to enable TLS without a hassle of having to generate, distribute, and manage certificates. But what if there are 2 pods and 2 services that have to use mTLS when communicating with each other. Since service serving certificates are already created and used for TLS, naturally we could try to use the same certificates as the client certificates. Not so fast, it turns out that the certificates that OpenShift generates for services are not suitable for client authentication. 

```
The extended error message from the SSL handshake exception is: Extended key usage does not permit use for TLS client authentication
```

To get around this limitation, follow these steps

1. Generate a new self-signed certificate

   ```
   openssl genrsa -out client.key 2048
   openssl req -new -key client.key -out client.csr -days 3650 -subj "/C=US/ST=California/L=Santa Cruz/O=TechCo/OU=Cloud/CN=microservice"
   ```

2. Get the OpenShift service-serving signing CA certificate and key

   ```
   oc get secret signing-key -n openshift-service-ca -o jsonpath="{.data['tls\.key']}" | base64 -d > ca.key
   oc get secret signing-key -n openshift-service-ca -o jsonpath="{.data['tls\.crt']}" | base64 -d > ca.crt
   ```

3. Sign the newly generated certificate with the OpenShift service-serving signing CA certificate 

   ```
   openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -CAserial client.srl -out client.crt -sha256 -extfile client.ext
   ```
  
   where client.ext  

   ```
   authorityKeyIdentifier=keyid,issuer
   basicConstraints=CA:FALSE
   keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
   subjectAltName = @alt_names

   [alt_names]
   DNS.1 = microservice-client.mtls-test.svc 
   ```
   
4. Create a secret containing the certificate and the key

   ```
   oc create secret tls mtls-microservice-client --key="client.key" --cert="client.crt" -n mtls-test
   ```

5. Create a registry pull secret

   ```
   DOCKER_REGISTRY_SERVER=docker.io
   DOCKER_USER=Type your dockerhub username, same as when you `docker login`
   DOCKER_EMAIL=Type your dockerhub email, same as when you `docker login`
   DOCKER_PASSWORD=Type your dockerhub pw, same as when you `docker login`

   oc create secret docker-registry pull-secret -n mtls-test \
     --docker-server=$DOCKER_REGISTRY_SERVER \
     --docker-username=$DOCKER_USER \
     --docker-password=$DOCKER_PASSWORD \
     --docker-email=$DOCKER_EMAIL
   ```

6. Create pods, service, and configmap
   
   ```
   oc apply -f mtls-test.yaml
   ```
   
7. Test the certificate with the following command.

   ```
   oc exec -it microservice-client sh
   ```

   then

   ```
   curl --cacert /cert-ca/service-ca.crt --cert /cert/tls.crt --key /cert/tls.key https://microservice.mtls-test.svc.cluster.local:443
   ```

The certificate expiration is set to 10 years, but, if there is a need to rotate it, re-run steps 1-4.


