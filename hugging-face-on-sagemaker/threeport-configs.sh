#!/bin/bash

HELP="Generate configs for distilbert app.
Usage: \r
./threeport-configs.sh \ \r
    <AWS region> \ \r
    <AWS Principal for role assumption> \ \r
    <AWS access key ID> \ \r
    <AWS secret access key> \ \r
    <AWS Secret Manager name> \ \r
    <AWS Route 53 hosted zome domain> \ \r
    <Threeport Kubernetes runtime instance> \r
"

REGION=$1
AWS_PRINCIPAL=$2
ACCESS_KEY_ID=$3
SECRET_ACCESS_KEY=$4
SECRET_NAME=$5
DNS=$6
RUNTIME=$7

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
echo "AWS principal: $AWS_PRINCIPAL"
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
        image: ghcr.io/threeport/distilbert-deploy:v0.1.0
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
        - name: AWS_ROLE_NAME
          valueFrom:
            configMapKeyRef:
              name: aws-role
              key: aws-role-name
      containers:
      - name: distilbert
        image: ghcr.io/threeport/distilbert-run:v0.1.0
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
        - name: AWS_ROLE_NAME
          valueFrom:
            configMapKeyRef:
              name: aws-role
              key: aws-role-name
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-role
data:
  aws-role-name: distilbert_sagemaker_role
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

cat > terraform/terraform.tfvars <<EOF
region = "${REGION}"
principal = "${AWS_PRINCIPAL}"
EOF

cat > distilbert-terraform.yaml <<EOF
Terraform:
  Name: distilbert-iam-role
  ConfigDir: terraform
  VarsDocument: terraform/terraform.tfvars
  AwsAccount:
    Name: default-account
EOF

echo "Configs generated"
exit 0

