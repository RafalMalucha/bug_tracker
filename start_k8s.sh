#!/bin/bash

set -e

source .env

kubectl delete secret user-db-secret --ignore-not-found
kubectl create secret generic user-db-secret \
  --from-literal=POSTGRES_DB=$USER_DB_NAME \
  --from-literal=POSTGRES_USER=$USER_DB_USER \
  --from-literal=POSTGRES_PASSWORD=$USER_DB_PASS

kubectl delete secret project-db-secret --ignore-not-found
kubectl create secret generic project-db-secret \
  --from-literal=POSTGRES_DB=$PROJECT_DB_NAME \
  --from-literal=POSTGRES_USER=$PROJECT_DB_USER \
  --from-literal=POSTGRES_PASSWORD=$PROJECT_DB_PASS

echo "Starting Minikube..."
minikube start --driver=docker

echo "Configuring Docker to use Minikube environment..."
eval $(minikube docker-env)

echo "Building Docker images..."
docker build -t user-service:dev ./user-service
docker build -t project-service:dev ./project-service

echo "Applying PostgreSQL resources..."

# User DB
kubectl apply -f ./k8s/user-postgres-pv.yaml
kubectl apply -f ./k8s/user-postgres-deployment.yaml
kubectl apply -f ./k8s/user-postgres-service.yaml

# Project DB
kubectl apply -f ./k8s/project-postgres-pv.yaml
kubectl apply -f ./k8s/project-postgres-deployment.yaml
kubectl apply -f ./k8s/project-postgres-service.yaml

echo "Deploying services..."
kubectl apply -f ./k8s/user-service.yaml
kubectl apply -f ./k8s/project-service.yaml

echo "Restarting deployments to use local images..."
kubectl rollout restart deployment user-service
kubectl rollout restart deployment project-service

echo "Waiting for services to become ready..."
kubectl rollout status deployment user-service
kubectl rollout status deployment project-service
kubectl rollout status deployment user-postgres
kubectl rollout status deployment project-postgres

echo "Starting port forwarding..."
kubectl port-forward service/user-service 8081:8081 &
kubectl port-forward service/project-service 8082:8082 &

kubectl port-forward service/user-postgres 5433:5432 &
kubectl port-forward service/project-postgres 5434:5432 &
