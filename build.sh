docker build -t microservice .

docker tag microservice DOCKER_USER/microservice:latest
docker push DOCKER_USER/microservice:latest
