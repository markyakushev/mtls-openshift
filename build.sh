docker build -t microservice .

docker tag microservice USER_NAME/microservice:latest
docker push USER_NAME/microservice:latest
