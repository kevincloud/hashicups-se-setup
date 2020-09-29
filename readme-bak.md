docker run -d -p6831:6831/udp -p16686:16686 jaegertracing/all-in-one:latest

docker build -t hashicorpdemoapp/product-api:local . && \
docker tag hashicorpdemoapp/product-api:local localhost:5000/product-api:local  && \
docker push localhost:5000/product-api:local


docker build -t hashicorpdemoapp/public-api:local . && \
docker tag hashicorpdemoapp/public-api:local localhost:5000/public-api:local && \
docker push localhost:5000/public-api:local


kind create cluster --name hashicups

docker build -t product-api:local ../product-api-go && \
kind load docker-image product-api:local --name hashicups && \
docker build -t public-api:local ../public-api && \
kind load docker-image public-api:local --name hashicups