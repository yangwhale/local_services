#!/bin/bash

# Author: Bin Wu <binwu@google.com>

pwd=`pwd`
cluster_name=elk
region=asia-east1
# zone=asia-east1-a
project_id=google.com:bin-wus-learning-center
default_pool=default-pool
nodes_per_zone=5 # per zone
machine_type=n2-standard-8

__usage() {
    echo "Usage: ./bin/gke.sh {create|(delete,del,d)|scale|fix}"
}

__create() {
        #--zone "${zone}" \
        #--node-locations "${region}-a,${region}-b,${region}-c"
        #--num-nodes "1" for regional/multi-zone cluster, this is the number in each zone
    gcloud beta container \
        --project "${project_id}" clusters create "$cluster_name" \
        --region "${region}" \
        --node-locations "${region}-a","${region}-b" \
        --no-enable-basic-auth \
        --enable-dataplane-v2 \
        --release-channel "rapid" \
        --machine-type "$machine_type" \
        --image-type "COS" \
        --disk-type "pd-ssd" \
        --disk-size "100" \
        --metadata disable-legacy-endpoints=true \
        --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
        --num-nodes "$nodes_per_zone" \
        --enable-stackdriver-kubernetes \
        --enable-ip-alias \
        --network "projects/${project_id}/global/networks/default" \
        --subnetwork "projects/${project_id}/regions/$region/subnetworks/default" \
        --default-max-pods-per-node "110" \
        --no-enable-master-authorized-networks \
        --addons HorizontalPodAutoscaling,HttpLoadBalancing \
        --enable-autoupgrade \
        --enable-autorepair

    # Set kubectl to target the created cluster
    gcloud container clusters get-credentials $cluster_name \
        --region ${region} \
        --project ${project_id}

    # sysctl -w vm.max_map_count=262144 for every GKE node
    # Option 1
    # $pwd/bin/gke_sysctl_vmmaxmapcount.sh
    # Option 2
    kubectl apply -f $pwd/conf/node-daemon.yml

    # Install ECK: deploy Elastic operator
    # https://download.elastic.co/downloads/eck/1.2.1/all-in-one.yaml
    kubectl apply -f $pwd/conf/all-in-one.yaml

    # create storage class
    kubectl create -f $pwd/conf/storage.yml

    ## make it default

    # 1. switch default class to false
    #kubectl patch storageclass standard \
        #-p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

    # 2. switch the default class to true for custom storage class
    #kubectl patch storageclass dingo-pdssd \
        #-p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

    # Optional: setup a GCP service account that can manipulate GCS for snapshots
    kubectl create secret generic gcs-credentials \
        --from-file=$pwd/conf/gcs.client.default.credentials_file
}

__add_preemptible_pool() {
    gcloud beta container \
    --project "${project_id}" node-pools create "preemptible" \
    --cluster "$cluster_name" \
    --region "${region}" \
    --machine-type "n2-standard-2" \
    --image-type "COS" \
    --disk-type "pd-ssd" \
    --disk-size "100" \
    --metadata disable-legacy-endpoints=true \
    --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    --preemptible \
    --num-nodes "1" \
    --enable-autoscaling \
    --min-nodes "1" \
    --max-nodes "10" \
    --enable-autoupgrade \
    --enable-autorepair
}

__delete() {
    echo "Y" | gcloud container clusters delete $cluster_name \
        --region $region
}

__scale() {
    # for a regional cluster, --num-nodes is the number for each zone
    # or you could only specify --zone here

    echo "Y" | gcloud container clusters resize $cluster_name \
        --project "${project_id}" \
        --region "${region}" \
        --node-pool $default_pool \
        --num-nodes "$1"
}

__fix() {
    $pwd/bin/gke_sysctl_vmmaxmapcount.sh fix
}

__check() {
    $pwd/bin/gke_sysctl_vmmaxmapcount.sh check
}

__main() {
    if [ $# -eq 0 ]
    then
        __usage
    else
        case $1 in
            create|c)
                __create
                ;;
            delete|del|d)
                __delete
                ;;
            scale|s)
                __scale $2
                ;;
            fix|f)
                __fix
                ;;
            check|chk)
                __check
                ;;
            *)
                __usage
                ;;
        esac
    fi
}

__main $@
