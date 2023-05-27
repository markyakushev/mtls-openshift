docker build -t microservice .

docker tag microservice barsik/microservice:latest
docker push barsik/microservice:latest
