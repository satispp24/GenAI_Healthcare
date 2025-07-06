import boto3
import os
import json
import time
import urllib.request
from generate_note import generate_soap_note

s3 = boto3.client('s3')
transcribe = boto3.client('transcribe')

UPLOAD_BUCKET = os.environ['UPLOAD_BUCKET']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        audio_file = body['audioFile']
        job_name = f"medtrans-{int(time.time())}"
        audio_uri = f"s3://{UPLOAD_BUCKET}/{audio_file}"

        # Start transcription
        transcribe.start_medical_transcription_job(
            MedicalTranscriptionJobName=job_name,
            LanguageCode='en-US',
            MediaFormat='wav',
            Media={'MediaFileUri': audio_uri},
            Specialty='PRIMARYCARE',
            Type='CONVERSATION'
        )

        # Wait for completion
        for _ in range(30):
            status = transcribe.get_medical_transcription_job(MedicalTranscriptionJobName=job_name)
            job_status = status['MedicalTranscriptionJob']['TranscriptionJobStatus']
            
            if job_status == 'COMPLETED':
                transcript_uri = status['MedicalTranscriptionJob']['Transcript']['TranscriptFileUri']
                
                # Get transcript content
                with urllib.request.urlopen(transcript_uri) as response:
                    transcript_data = json.loads(response.read())
                    transcript_text = transcript_data['results']['transcripts'][0]['transcript']
                
                # Generate SOAP note
                soap_note = generate_soap_note(transcript_text)
                
                # Save SOAP note
                note_key = audio_file.replace('.wav', '_soap_note.txt')
                s3.put_object(Bucket=UPLOAD_BUCKET, Key=note_key, Body=soap_note)
                
                return {
                    'statusCode': 200,
                    'headers': {
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'POST',
                        'Access-Control-Allow-Headers': 'Content-Type'
                    },
                    'body': json.dumps({
                        'noteLocation': f"https://{UPLOAD_BUCKET}.s3.amazonaws.com/{note_key}",
                        'transcript': transcript_text,
                        'soapNote': soap_note
                    })
                }
            
            elif job_status == 'FAILED':
                return {
                    'statusCode': 500,
                    'headers': {'Access-Control-Allow-Origin': '*'},
                    'body': json.dumps({'error': 'Transcription failed'})
                }
            
            time.sleep(10)
        
        # Timeout
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': 'Transcription timed out'})
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': f'Processing failed: {str(e)}'})
        }

