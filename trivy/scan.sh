#!/bin/bash
IMAGE=$1
if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <image>"
  exit 1
fi
trivy image --severity CRITICAL,HIGH $IMAGE
if [ $? -ne 0 ]; then
  echo "Trivy scan failed for image: $IMAGE"
  exit 1
fi
echo "Trivy scan completed successfully for image: $IMAGE"
echo "Scan results are available above."