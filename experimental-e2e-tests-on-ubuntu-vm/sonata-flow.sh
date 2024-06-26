#!/bin/bash

set -x
set -e

# Namespace for Sonataflow
kubectl create namespace sonataflow-infra

# PostgreSQL installation
kubectl create secret generic sonataflow-psql-postgresql --from-literal=postgres-username=postgres --from-literal=postgres-password=postgres -n sonataflow-infra
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install sonataflow-psql bitnami/postgresql --version 12.12.10 \
-f https://raw.githubusercontent.com/rgolangh/orchestrator-helm-chart/main/postgresql/values.yaml \
-n sonataflow-infra

sleep 60
kubectl wait --for=jsonpath='{.status.phase}'=Running "$(kubectl get pod -o name -n sonataflow-infra | grep sonataflow-psql-postgresql)" --timeout=300s -n sonataflow-infra

# Sonataflow operator
kubectl create -f https://raw.githubusercontent.com/kiegroup/kogito-serverless-operator/main/operator.yaml
kubectl apply -f https://raw.githubusercontent.com/rhkp/sonataflow-cluster-resources/main/sonata-flow-operator.yaml
kubectl wait --for=jsonpath='{.status.phase}'=Running "$(kubectl get pod -o name -n sonataflow-operator-system | grep sonataflow-operator-controller-manager)" -n sonataflow-operator-system  --timeout=300s

# Core services of Sonataflow
kubectl apply -f https://raw.githubusercontent.com/rhkp/sonataflow-cluster-resources/main/sonata-flow-platform.yaml
sleep 60
kubectl wait --for=jsonpath='{.status.phase}'=Running "$(kubectl get pod -o name -n sonataflow-infra | grep sonataflow-platform-jobs-service)" -n sonataflow-infra --timeout=300s
kubectl wait --for=jsonpath='{.status.phase}'=Running "$(kubectl get pod -o name -n sonataflow-infra | grep sonataflow-platform-data-index-service)" -n sonataflow-infra --timeout=300s