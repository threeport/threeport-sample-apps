# POC for HuggingFace Model on AWS Sagemaker

Run a web application that uses a HuggingFace model on SageMaker for inference.

Create a kind cluster:

```bash
kind create cluster
```

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

