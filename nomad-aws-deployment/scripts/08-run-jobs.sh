#!/bin/bash

echo "Submitting db-postres job..."
curl -X POST --data @/root/jobs/db-postgres.json http://localhost:4646/v1/jobs

echo "Submitting product-api job..."
curl -X POST --data @/root/jobs/products-api.json http://localhost:4646/v1/jobs

echo "Submitting public-api job..."
curl -X POST --data @/root/jobs/public-api.json http://localhost:4646/v1/jobs

echo "Submitting nginx-proxy job..."
curl -X POST --data @/root/jobs/nginx-proxy.json http://localhost:4646/v1/jobs

echo "Submitting frontend job..."
curl -X POST --data @/root/jobs/frontend.json http://localhost:4646/v1/jobs
