import boto3
import json
import os

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')

def generate_soap_note(transcript_text):
    prompt = f"""
Human: Convert the following medical transcript into a SOAP note:
\"\"\"
{transcript_text}
\"\"\"

Assistant:
"""

    response = bedrock.invoke_model(
        modelId="anthropic.claude-3-sonnet-20240229-v1:0",
        body=json.dumps({
            "prompt": prompt,
            "max_tokens_to_sample": 1000,
            "temperature": 0.7,
            "top_k": 250,
            "top_p": 0.9,
            "stop_sequences": ["\n\nHuman:"]
        }),
        contentType="application/json",
        accept="application/json"
    )

    response_body = json.loads(response['body'].read())
    return response_body['completion']
