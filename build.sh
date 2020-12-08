#!/bin/bash

HELM_RELEASE=$1

set -euo pipefail

export DOCKER_REPO=ghcr.io/mzehrer/helm-kubectl-docker
export K8S_VERSION=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/kubernetes/kubernetes/releases/latest | cut -d '/' -f 8)
if [ "$HELM_RELEASE" == "helm3" ];then
  export HELM_VERSION=$(curl -Ls https://github.com/helm/helm/releases | grep "/helm/helm/releases/tag/v3" | head -n 1 | sed 's/[^"]*"\([^"]*\)"[^"]*/\1/g' | cut -d '/' -f 6)
else
  export HELM_VERSION=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/helm/helm/releases/latest | cut -d '/' -f 8)
fi
export RELEASE=${K8S_VERSION}-${HELM_VERSION}

docker manifest inspect ${DOCKER_REPO}:${RELEASE} > /dev/null && echo "Version ${RELEASE} is already exists" && exit 0

# Build image
docker build -t ${DOCKER_REPO}:${RELEASE} \
    --build-arg K8S_VERSION=${K8S_VERSION} \
    --build-arg HELM_VERSION=${HELM_VERSION} .

if [ "$HELM_RELEASE" != "helm3" ];then
docker tag ${DOCKER_REPO}:${RELEASE} ${DOCKER_REPO}:latest
fi

# Push image
docker push ${DOCKER_REPO}:${RELEASE}

if [ "$HELM_RELEASE" != "helm3" ];then
docker push ${DOCKER_REPO}:latest
fi
