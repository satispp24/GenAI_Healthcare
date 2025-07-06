import boto3
import json
import os

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')

def generate_soap_note(transcript_text):
    try:
        prompt = f"""Convert the following medical transcript into a SOAP note format:

Transcript:
{transcript_text}

Please format as:
S (Subjective): Patient's reported symptoms
O (Objective): Observable findings
A (Assessment): Clinical assessment
P (Plan): Treatment plan"""

        response = bedrock.invoke_model(
            modelId="anthropic.claude-3-sonnet-20240229-v1:0",
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                "temperature": 0.3,
                "top_p": 0.9
            }),
            contentType="application/json",
            accept="application/json"
        )

        response_body = json.loads(response['body'].read())
        return response_body['content'][0]['text']
    
    except Exception as e:
        print(f"Error generating SOAP note: {str(e)}")
        return f"Error generating SOAP note: {str(e)}"
