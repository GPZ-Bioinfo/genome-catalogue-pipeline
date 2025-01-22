#!/bin/bash

set -e

docker login quay.io

export REPO="genomes-pipeline"

export DOCKERHUB_NAME="microbiomeinformatics"
export QUAY_NAME="quay.io/microbiome-informatics"

export STORAGE=${QUAY_NAME}

num_containers=9

containers_versions=(
    'eggnog-mapper:v2.1.11'
    'ips:5.62-94.0'
    'python3base:v1.1'
)

for ((i = 0; i < num_containers; i++)); do
    echo "${containers_versions[${i}]}"
    docker push "${STORAGE}/${REPO}.${containers_versions[${i}]}"
done
