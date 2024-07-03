# Threeport Sample for HuggingFace Model on AWS Sagemaker

The instructions below are to install a sample workload on AWS EKS that uses
AWS SageMaker for inference on a trained HuggingFace model.

## Install in Remote Runtime Using Threeport

Requires:

* [tptctl installed](https://docs.threeport.io/install/install-tptctl/)
* [Threeport control plane running in
  AWS](https://docs.threeport.io/install/install-threeport-aws/)

Create secret definition config.  In this step we're setting environment
variables for AWS credentials.  The credentials must have permissions to manage
SageMaker inference models and endpoints.  The `threeport-secret.sh` script
creates a Threeport secret definition for those AWS creds.

```bash
export AWS_DEFAULT_REGION=[aws region]
export AWS_ACCESS_KEY_ID=[access key ID]
export AWS_SECRET_ACCESS_KEY=[secret access key]
./threeport-secret.sh
```

Create secret definition for AWS credentials.  This step puts those AWS
credentials in AWS Secret Manager.

```bash
tptctl create secret-definition -c distilbert-secret-definition.yaml
```

Deploy distilbert app to remote runtime:

```bash
tptctl create workload -c distilbert-workload-remote.yaml
```

Create secret instance for distilbert app.  This step exposes the credentials
stored in AWS Secret Manager to the distilbert app.

```bash
tptctl create secret-instance -c distilbert-secret-instance.yaml
```



## Direct Kubernetes Install

Run a web application that uses a HuggingFace model on SageMaker for inference.

Create a kind cluster:

```bash
kind create cluster
```

Set env vars:

```bash
export DEPLOY_IMG=<image name>
export RUN_IMG=<image name>

Build the container images:

```bash
make build-all
```

Either push the image to a registry, or load it into the cluster pre-deployment.

To push:

```bash
make push-all
```

To load into kind cluster:

```bash
make load-all
```

Deploy app:

```bash
make install
```

Expose the app with a port forward:

```bash
kubectl port-forward -n distilbert svc/distilbert 5000:80
```

Visit the app in your browser: http://localhost:5000

Uninstall the app:

```bash
make uninstall
```

Delete kind cluster:

```bash
kind delete cluster
```

## Development

Initialize virtualenv:

```bash
virtualenv venv
```

Activate virtualenv:

```bash
source venv/bin/activate
```

Install python dependencies:

```bash
pip install -r requirements.txt
```

Run local Flask dev server:

```bash
make dev-server
```

