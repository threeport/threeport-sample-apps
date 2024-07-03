#!/bin/bash

HELP="Generate configs for distilbert app.
Usage: \r
./threeport-configs.sh \ \r
    <AWS region> \ \r
    <AWS access key ID> \ \r
    <AWS secret access key> \ \r
    <AWS Secret Manager name> \ \r
    <AWS Route 53 hosted zome domain> \ \r
    <Threeport Kubernetes runtime instance> \r
"

REGION=$1
ACCESS_KEY_ID=$2
SECRET_ACCESS_KEY=$3
SECRET_NAME=$4
DNS=$5
RUNTIME=$6

# ensure all args are passed in
for arg in "$REGION" "$ACCESS_KEY_ID" "$SECRET_ACCESS_KEY" "$SECRET_NAME" "$DNS" "$RUNTIME"; do
    if [ -z "$arg" ]; then
        echo "Error: missing argument"
        printf "$HELP"
        exit 1
    fi
done

# check inputs
echo "These are your inputs:"
echo "AWS region: $REGION"
echo "AWS access key ID: $ACCESS_KEY_ID" | sed -E 's/(:....).*/\1***/'
echo "AWS secret access key: $SECRET_ACCESS_KEY" | sed -E 's/(:....).*/\1***/'
echo "AWS Secret Manager secret name: $SECRET_NAME"
echo "Domain name for AWS Route 53 hosted zone: $DNS"
echo "Threeport Kubernetes runtime instance name: $RUNTIME"

read -r -p "Does this look correct? [y/n] " response
if [[ "$response" =~ ^([yY])$ ]]; then
    echo "Generating configs..."
else
    echo "Exiting"
    exit 0
fi

cat > distilbert-secret-definition.yaml <<EOF
SecretDefinition:
  Name: "${SECRET_NAME}"
  AwsAccountName: default-account
  Data:
    aws-region: "${REGION}"
    aws-access-key-id: "${ACCESS_KEY_ID}"
    aws-secret-access-key: "${SECRET_ACCESS_KEY}"
EOF

cat > distilbert-secret-instance.yaml <<EOF
SecretInstance:
  Name: "${SECRET_NAME}"
  SecretDefinition:
    Name: "${SECRET_NAME}"
  WorkloadInstance:
    Name: distilbert
  KubernetesRuntimeInstance:
    Name: "${RUNTIME}"
EOF

cat > distilbert-workload.yaml <<EOF
Workload:
  Name: distilbert
  YAMLDocument: distilbert-manifest.yaml
  DomainName:
    Name: "${DNS}"
    Domain: "${DNS}"
    Zone: Public
    AdminEmail: richard@qleet.io
  Gateway:
    Name: web-service-gateway
    HttpPorts:
      - Port: 80
        HTTPSRedirect: true
        Path: "/"
      - Port: 443
        TLSEnabled: true
        Path: "/"
    ServiceName: distilbert
    SubDomain: distilbert
EOF

cat > distilbert-manifest.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: distilbert
  labels:
    app: distilbert
spec:
  replicas: 1
  selector:
    matchLabels:
      app: distilbert
  template:
    metadata:
      labels:
        app: distilbert
    spec:
      restartPolicy: Always
      volumes:
      - name: shared-data
        emptyDir: {}
      initContainers:
      - name: deploy-model
        #image: ghcr.io/threeport-samples/distilbert-deploy:v0.1.0
        image: richlander2k2/distilbert-deploy:latest
        imagePullPolicy: Always
        volumeMounts:
        - name: shared-data
          mountPath: /shared-data
        env:
        - name: AWS_DEFAULT_REGION
          valueFrom:
            secretKeyRef:
              name: "${SECRET_NAME}"
              key: aws-region
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: "${SECRET_NAME}"
              key: aws-access-key-id
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: "${SECRET_NAME}"
              key: aws-secret-access-key
      containers:
      - name: distilbert
        #image: ghcr.io/threeport-samples/distilbert-run:v0.1.0
        image: richlander2k2/distilbert-run:latest
        imagePullPolicy: Always
        lifecycle:
          preStop:
            exec:
              command: ["python3", "/usr/src/app/delete_model_endpoint.py"]
        volumeMounts:
        - name: shared-data
          mountPath: /shared-data
        ports:
        - name: http
          containerPort: 5000
        env:
        - name: AWS_DEFAULT_REGION
          valueFrom:
            secretKeyRef:
              name: "${SECRET_NAME}"
              key: aws-region
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: "${SECRET_NAME}"
              key: aws-access-key-id
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: "${SECRET_NAME}"
              key: aws-secret-access-key
---
apiVersion: v1
kind: Service
metadata:
  name: distilbert
spec:
  selector:
    app: distilbert
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
  - name: https
    port: 443
    protocol: TCP
    targetPort: http
EOF

echo "Configs generated"
exit 0

