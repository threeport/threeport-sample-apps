from flask import Flask, render_template, request

import boto3
import json
import os

app = Flask(__name__)

@app.route("/")
def nlp():
    return render_template('nlp.html')

@app.route("/answer/", methods=['POST'])
def answer():
    form_data = request.form
    response = get_response(form_data['question'], form_data['context'])
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

    # create a low-level client representing Amazon SageMaker runtime
    sagemaker_runtime = boto3.client(
        "sagemaker-runtime",
        region_name=region,
        aws_access_key_id=access_key_id,
        aws_secret_access_key=secret_access_key,
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

