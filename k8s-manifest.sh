#!/bin/bash

REGION=$(echo -n ${AWS_DEFAULT_REGION} | base64)
KEY_ID=$(echo -n ${AWS_ACCESS_KEY_ID} | base64)
ACCESS_KEY=$(echo -n ${AWS_SECRET_ACCESS_KEY} | base64)

cat > distilbert-app.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: distilbert
---
apiVersion: v1
kind: Secret
metadata:
  name: aws-creds
  namespace: distilbert
type: Opaque
data:
  aws-region: "${REGION}"
  aws-access-key-id: "${KEY_ID}"
  aws-secret-access-key: "${ACCESS_KEY}"
---
apiVersion: v1
kind: Pod
metadata:
  name: distilbert
  namespace: distilbert
spec:
  restartPolicy: Never
  volumes:
  - name: shared-data
    emptyDir: {}
  initContainers:
  - name: deploy-model
    image: ${DEPLOY_IMG}
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: shared-data
      mountPath: /shared-data
    env:
    - name: AWS_DEFAULT_REGION
      valueFrom:
        secretKeyRef:
          name: aws-creds
          key: aws-region
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: aws-creds
          key: aws-access-key-id
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: aws-creds
          key: aws-secret-access-key
  containers:
  - name: distilbert
    image: ${RUN_IMG}
    imagePullPolicy: IfNotPresent
    lifecycle:
      preStop:
        exec:
          command: ["python3", "/usr/src/app/delete_model_endpoint.py"]
    volumeMounts:
    - name: shared-data
      mountPath: /shared-data
    env:
    - name: AWS_DEFAULT_REGION
      valueFrom:
        secretKeyRef:
          name: aws-creds
          key: aws-region
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: aws-creds
          key: aws-access-key-id
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: aws-creds
          key: aws-secret-access-key
---
apiVersion: v1
kind: Service
metadata:
  name: distilbert
  namespace: distilbert
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 5000
EOF

