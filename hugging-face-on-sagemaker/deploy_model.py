from sagemaker.huggingface import HuggingFaceModel
import sagemaker
import boto3
import os

region = os.environ['AWS_DEFAULT_REGION'].rstrip()
access_key_id = os.environ['AWS_ACCESS_KEY_ID'].rstrip()
secret_access_key = os.environ['AWS_SECRET_ACCESS_KEY'].rstrip()
aws_role_name = os.environ['AWS_ROLE_NAME'].rstrip()

print(f"deploying model to {region} region")

# create boto client and get execution role
iam = boto3.client(
    'iam',
    region_name=region,
    aws_access_key_id=access_key_id,
    aws_secret_access_key=secret_access_key,
)
role = iam.get_role(RoleName=aws_role_name)['Role']['Arn']

print(f"sagemaker role arn: {role}")

# specify HuggingFace model configuration. https://huggingface.co/models
hub = {
    'HF_MODEL_ID':'distilbert-base-uncased-distilled-squad', # model_id from hf.co/models
    'HF_TASK':'question-answering' # NLP task you want to use for predictions
}

# create HuggingFace model class
huggingface_model = HuggingFaceModel(
    env=hub,
    role=role, # iam role with permissions to create a Model and Endpoint
    transformers_version="4.26", # transformers version used
    pytorch_version="1.13", # pytorch version used
    py_version="py39", # python version of the DLC
)

# deploy model to SageMaker Inference
predictor = huggingface_model.deploy(
    initial_instance_count=1,
    instance_type="ml.m5.large"
)

print(f"model endpoint: {predictor.endpoint_name}")

# record the SageMaker endpoint on shared volume
f = open("/shared-data/sagemaker_endpoint.txt", "w")
f.write(predictor.endpoint_name)
f.close()

print(f"model deployment complete")

