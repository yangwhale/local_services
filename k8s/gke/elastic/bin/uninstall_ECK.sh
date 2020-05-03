#!/bin/bash

kubectl get namespaces --no-headers -o custom-columns=:metadata.name \
      | xargs -n1 kubectl delete elastic --all -n

# https://download.elastic.co/downloads/eck/1.0.1/all-in-one.yaml
kubectl delete -f $pwd/conf/all-in-one.yaml
