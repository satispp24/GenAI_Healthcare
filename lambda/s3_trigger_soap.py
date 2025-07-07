import boto3
import json
import os
from generate_note import generate_soap_note

s3 = boto3.client('s3')

def lambda_handler(event, context):
    try:
        # Process S3 event
        for record in event['Records']:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            
            # Only process JSON files in medical/ folder
            if not (key.startswith('medical/') and key.endswith('.json')):
                print(f"⏭️ Skipping non-transcript file: {key}")
                continue
            
            print(f"📥 Processing transcript: {key}")
            
            # Download transcript
            obj = s3.get_object(Bucket=bucket, Key=key)
            transcript_data = json.loads(obj['Body'].read())
            transcript_text = transcript_data['results']['transcripts'][0]['transcript']
            
            print(f"📝 Transcript: {transcript_text}")
            
            # Generate SOAP note
            print("🤖 Generating SOAP note with Bedrock...")
            soap_note = generate_soap_note(transcript_text)
            
            # Save SOAP note
            soap_key = key.replace('.json', '_soap_note.txt')
            s3.put_object(Bucket=bucket, Key=soap_key, Body=soap_note)
            
            print(f"✅ SOAP note saved: {soap_key}")
            
        return {'statusCode': 200, 'body': 'SOAP notes generated successfully'}
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}