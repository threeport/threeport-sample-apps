from flask import Flask, request, request, render_template, request

import boto3
import json
import os

app = Flask(__name__)

@app.route("/")
def nlp():
    return render_template('nlp.html')

@app.route("/answer/", methods=['GET', 'POST'])
def answer():
    form_data = {}
    question = request.form.get("question")
    context = request.form.get("context")
    form_data["question"] = question
    form_data["context"] = context

    response = get_response(question, context)
    resp_data = json.loads(response)
    answer = resp_data['answer']
    certainty = f"{resp_data['score']:.0%}"

    return render_template(
        'answer.html',
        form_data=form_data,
        answer=answer,
        certainty=certainty,
    )

def get_response(question, context):
    region = os.environ['AWS_DEFAULT_REGION'].rstrip()
    access_key_id = os.environ['AWS_ACCESS_KEY_ID'].rstrip()
    secret_access_key = os.environ['AWS_SECRET_ACCESS_KEY'].rstrip()
    aws_role_name = os.environ['AWS_ROLE_NAME'].rstrip()

    # get execution role
    iam = boto3.client(
        'iam',
        region_name=region,
        aws_access_key_id=access_key_id,
        aws_secret_access_key=secret_access_key,
    )
    role = iam.get_role(RoleName=aws_role_name)['Role']['Arn']

    print(f"sagemaker role arn: {role}")

    # assume role and get credentials
    sts = boto3.client(
        'sts',
        region_name=region,
        aws_access_key_id=access_key_id,
        aws_secret_access_key=secret_access_key,
    )
    assumed_role = sts.assume_role(
        RoleArn=role,
        RoleSessionName="distilbert-session",
    )
    credentials = assumed_role['Credentials']

    # create a low-level client representing Amazon SageMaker runtime
    sagemaker_runtime = boto3.client(
        "sagemaker-runtime",
        region_name=region,
        #aws_access_key_id=access_key_id,
        #aws_secret_access_key=secret_access_key,
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
    )

    # retrieve the SageMaker endpoint from the shared volume
    f = open("/shared-data/sagemaker_endpoint.txt", "r")
    endpoint_name = f.read()
    f.close()

    data = {
        "inputs": {
            "question": question,
            "context": context,
        }
    }

    # gets inference from the model hosted at the specified endpoint
    response = sagemaker_runtime.invoke_endpoint(
        ContentType='application/json',
        EndpointName=endpoint_name.rstrip(),
        Body=json.dumps(data)
    )

    # decodes and returns the response body:
    return response['Body'].read().decode('utf-8')

