# HuggingFace Model on AWS Sagemaker

The instructions below are to install a sample workload on AWS EKS that uses
AWS SageMaker for inference on a trained HuggingFace model.

The app is called `distilbert`, the name of the model we're running on
SageMaker.

## Install on AWS Using Threeport

Requires:

* [tptctl installed](https://docs.threeport.io/install/install-tptctl/)
* [Threeport control plane running in
  AWS](https://docs.threeport.io/install/install-threeport-aws/)

Create secret definition config.  In this step we're setting environment
variables for AWS credentials.  The credentials must have permissions to manage
SageMaker inference models and endpoints.

The example below uses:

* The `us-east-2` region.
* An AWS Secret Manager secret name `aws-creds-00`.  Note: AWS Secret Manager
  reserves names for secrets for a period after deleteion.  So use a unique name
  that hasn't been used recently.
* A Route53 hosted zone called `qleet.net`
* A Kubernetes runtime instance called `threeport-demo`.  You can get the
  runtime instance name for your environment with:
  ```
  tptctl get kubernetes-runtime-instances
  ```

```bash
export AWS_ACCESS_KEY_ID=[access key ID]
export AWS_SECRET_ACCESS_KEY=[secret access key]
./threeport-configs.sh \
    us-east-2 \
    $AWS_ACCESS_KEY_ID \
    $AWS_SECRET_ACCESS_KEY \
    aws-creds-00 \
    qleet.net \
    threeport-demo
```

Create secret definition for AWS credentials.  This step puts those AWS
credentials in AWS Secret Manager.

```bash
tptctl create secret-definition -c distilbert-secret-definition.yaml
```

Deploy distilbert app to remote runtime.  This will deploy the sample app
workload, deploy the DistilBERT model to SageMaker, set up DNS and provision an
ingress gateway for requests to the sample app.  It will also provision TLS
certificates to terminate TLS for requests to the sample app.

```bash
tptctl create workload -c distilbert-workload.yaml
```

Create secret instance for distilbert app.  This step exposes the credentials
stored in AWS Secret Manager to the distilbert app.

```bash
tptctl create secret-instance -c distilbert-secret-instance.yaml
```

You can now visit http://distilbert.[your domain] in your browser.  Notice that the request is
redirected to HTTPS.  The default install uses the Let's Encrypt staging
environement so the TLS certificates will not be publicly trusted.  You'll have
to tell your browser to trust the certs.  Once you do, you'll see the DistilBERT
sample app with some sample context to use.

## Tear Down

Delete the app.  This will remove the running application as well as the SageMaker
model and endpoint.  It will also remove the DNS entries from Route53.

```bash
tptctl delete workload -c distilbert-workload.yaml
```

Remove the AWS credentials from AWS Secret Manager.

```bash
tptctl delete secret-definition -n aws-creds-00
```

## Development

Requires:

* python3
* virtualenv

Initialize virtualenv.

```bash
virtualenv venv
```

Activate virtualenv.

```bash
source venv/bin/activate
```

Install python dependencies.

```bash
pip install -r requirements.txt
```

Run local Flask dev server.

```bash
make dev-server
```

