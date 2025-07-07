#!/usr/bin/env python3
"""
Process existing transcript and generate SOAP note
"""
import boto3
import json
from generate_note import generate_soap_note

def process_existing_transcript():
    s3 = boto3.client('s3')
    bucket = 'genai-clinical-audio-bucket-unique-2024-7f0d6d94'
    transcript_key = 'medical/medtrans-1751840603.json'
    
    try:
        # Download transcript from S3
        print("📥 Downloading transcript from S3...")
        response = s3.get_object(Bucket=bucket, Key=transcript_key)
        transcript_data = json.loads(response['Body'].read())
        
        # Extract transcript text
        transcript_text = transcript_data['results']['transcripts'][0]['transcript']
        print(f"📝 Transcript: {transcript_text}")
        
        # Generate SOAP note using Bedrock
        print("🤖 Generating SOAP note with Bedrock...")
        soap_note = generate_soap_note(transcript_text)
        print(f"🏥 SOAP Note Generated:\n{soap_note}")
        
        # Save SOAP note to S3
        soap_key = 'medical/medtrans-1751840603_soap_note.txt'
        s3.put_object(Bucket=bucket, Key=soap_key, Body=soap_note)
        print(f"💾 SOAP note saved to: s3://{bucket}/{soap_key}")
        
        return {
            'transcript': transcript_text,
            'soapNote': soap_note,
            'location': f"s3://{bucket}/{soap_key}"
        }
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return None

if __name__ == "__main__":
    result = process_existing_transcript()
    if result:
        print("\n✅ Success! Transcript processed and SOAP note generated.")
    else:
        print("\n❌ Failed to process transcript.")