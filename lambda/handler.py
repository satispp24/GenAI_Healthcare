import boto3
import os
import json
import time

s3 = boto3.client('s3')
transcribe = boto3.client('transcribe')

UPLOAD_BUCKET = os.environ['UPLOAD_BUCKET']

def lambda_handler(event, context):
    body = json.loads(event['body'])
    audio_file = body['audioFile']
    job_name = f"medtrans-{int(time.time())}"

    audio_uri = f"s3://{UPLOAD_BUCKET}/{audio_file}"

    transcribe.start_medical_transcription_job(
        MedicalTranscriptionJobName=job_name,
        LanguageCode='en-US',
        MediaFormat='wav',
        Media={'MediaFileUri': audio_uri},
        Specialty='PRIMARYCARE',
        Type='CONVERSATION'
    )

    for _ in range(30):
        status = transcribe.get_medical_transcription_job(MedicalTranscriptionJobName=job_name)
        job_status = status['MedicalTranscriptionJob']['TranscriptionJobStatus']
        if job_status == 'COMPLETED':
            transcript_uri = status['MedicalTranscriptionJob']['Transcript']['TranscriptFileUri']
            break
        elif job_status == 'FAILED':
            return {
                'statusCode': 500,
                'body': json.dumps({'error': 'Transcription failed'})
            }
        time.sleep(10)
    else:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Transcription timed out'})
        }

    # For demo, we just echo the transcript URI in a SOAP note format
    note_text = f"SOAP Note Generated:\\n\\nTranscript URL: {transcript_uri}"

    note_key = audio_file.replace('.wav', '.txt')
    s3.put_object(Bucket=UPLOAD_BUCKET, Key=note_key, Body=note_text)

    return {
        'statusCode': 200,
        'body': json.dumps({'noteLocation': f"https://{UPLOAD_BUCKET}.s3.amazonaws.com/{note_key}"})
    }

