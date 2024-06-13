import boto3
import json
import os

region = os.environ['AWS_DEFAULT_REGION'].rstrip()
access_key_id = os.environ['AWS_ACCESS_KEY_ID'].rstrip()
secret_access_key = os.environ['AWS_SECRET_ACCESS_KEY'].rstrip()

# Create a low-level client representing Amazon SageMaker Runtime
sagemaker_client = boto3.client(
    "sagemaker",
    region_name=region,
    aws_access_key_id=access_key_id,
    aws_secret_access_key=secret_access_key,
)

# get endpoint name from the shared volume
f = open("/shared-data/sagemaker_endpoint.txt", "r")
endpoint_name = f.read().rstrip()
f.close()

# get the endpoint configuration name
endpoint_response = sagemaker_client.describe_endpoint(EndpointName=endpoint_name)
endpoint_config_name = endpoint_response['EndpointConfigName']

# get the model name from the endpoint configuration
endpoint_config_response = sagemaker_client.describe_endpoint_config(EndpointConfigName=endpoint_config_name)
production_variants = endpoint_config_response['ProductionVariants']
model_name = production_variants[0]['ModelName']  # Assuming a single variant

# delete the endpoint
try:
	print(f"Deleting endpoint: {endpoint_name}")
	sagemaker_client.delete_endpoint(EndpointName=endpoint_name)
	print(f"Endpoint {endpoint_name} deleted successfully.")
except Exception as e:
	print(f"Error deleting endpoint {endpoint_name}: {e}")

# delete the endpoint configuration
try:
	endpoint_response = sagemaker_client.describe_endpoint(EndpointName=endpoint_name)
	endpoint_config_name = endpoint_response['EndpointConfigName']
	print(f"Deleting endpoint configuration: {endpoint_config_name}")
	sagemaker_client.delete_endpoint_config(EndpointConfigName=endpoint_config_name)
	print(f"Endpoint configuration {endpoint_config_name} deleted successfully.")
except Exception as e:
	print(f"Error deleting endpoint configuration {endpoint_config_name}: {e}")

# delete the model
try:
	print(f"Deleting model: {model_name}")
	sagemaker_client.delete_model(ModelName=model_name)
	print(f"Model {model_name} deleted successfully.")
except Exception as e:
	print(f"Error deleting model {model_name}: {e}")

