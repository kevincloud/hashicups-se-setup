#!/bin/bash

echo "Submitting db-postres job..."
curl -X POST --header "X-Nomad-Token: $NOMAD_TOKEN" --data @/root/jobs/db-postgres.json http://localhost:4646/v1/jobs

echo "Submitting product-api job..."
curl -X POST --header "X-Nomad-Token: $NOMAD_TOKEN" --data @/root/jobs/products-api.json http://localhost:4646/v1/jobs

echo "Submitting payments-api job..."
curl -X POST --header "X-Nomad-Token: $NOMAD_TOKEN" --data @/root/jobs/payments-api.json http://localhost:4646/v1/jobs

echo "Submitting public-api job..."
curl -X POST --header "X-Nomad-Token: $NOMAD_TOKEN" --data @/root/jobs/public-api.json http://localhost:4646/v1/jobs

echo "Submitting frontend job..."
curl -X POST --header "X-Nomad-Token: $NOMAD_TOKEN" --data @/root/jobs/frontend.json http://localhost:4646/v1/jobs
